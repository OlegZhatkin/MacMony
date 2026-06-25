# MacMon

Лёгкое menubar-приложение мониторинга системы для macOS (Apple Silicon). Показывает в
строке меню и во всплывающем окне в стиле *liquid glass*:

- **Загрузка CPU** (%)
- **Температура CPU** (°C)
- **Обороты вентиляторов** (RPM)
- **Заполненность RAM** (использовано / всего, %)
- **Скорость сети** — download / upload

Данные обновляются автоматически по таймеру. Без иконки в Dock (`LSUIElement`) — приложение
живёт только в строке меню.

---

## Требования

- **Apple Silicon** (M1–M4)
- **macOS 14.0+**
- Xcode 16+ для сборки

## Сборка и запуск

```bash
# из папки проекта
xcodebuild -project MacMon.xcodeproj -scheme MacMon -configuration Release -derivedDataPath build build
open build/Build/Products/Release/MacMon.app
```

Или открыть `MacMon.xcodeproj` в Xcode и нажать ⌘R.

Собрать DMG для распространения:

```bash
./build_dmg.sh
```

## Возможности

- **Настраиваемый индикатор в строке меню** — иконка + любой набор значений
  (CPU %, температура, RAM %, сеть ↓). Настраивается в окне настроек.
- **Цветовые пороги** (normal / warm / hot) с окраской баров и значений; при `hot` —
  мягкое свечение бара.
- **Автозапуск при входе** через `SMAppService`.
- **Интервал опроса** 1 / 2 / 5 с (по умолчанию 2 с), применяется на лету.
- **Настраиваемый порог температуры** (граница warm/hot).
- Тёмная / светлая тема — автоматически (системный материал `NSVisualEffectView`).

## Архитектура

```
MacMon/
├── MacMonApp.swift             @main, MenuBarExtra, .window-стиль
├── Core/
│   ├── Models.swift            метрики, статусы, форматирование
│   ├── PollingTimer.swift      пересоздаваемый таймер опроса
│   └── MetricsStore.swift      ObservableObject, @Published-метрики, владелец таймера
├── Sensors/
│   ├── Sensor.swift            общий протокол
│   ├── CPUSensor.swift         host_processor_info (дельта тиков)
│   ├── MemorySensor.swift      host_statistics64
│   ├── NetworkSensor.swift     getifaddrs + дельта RX/TX
│   └── SMC/
│       ├── SMCService.swift    фасад: temp() + fans(), мягкая деградация
│       ├── HIDTemperature.swift агрегатор температуры (Swift)
│       ├── HIDReader.{h,m}      приватный IOHIDEventSystemClient (температура)
│       └── SMCFanReader.{h,m}   AppleSMC IOKit (вентиляторы)
├── UI/
│   ├── Theme.swift             цвета, пороги, геометрия
│   ├── MetricRow.swift         строка метрики + бар (скругление справа)
│   ├── PopoverView.swift       главное окно (liquid glass) + блок сети
│   ├── MenuBarLabel.swift      настраиваемый индикатор в строке меню
│   └── SettingsView.swift      настройки
└── Services/
    └── LaunchAtLogin.swift     обёртка над SMAppService
```

Поток данных: `PollingTimer` тикает → сенсоры читают значения в фоновом потоке →
`MetricsStore` публикует `@Published`-свойства на главном → SwiftUI перерисовывает UI.

## Датчики на Apple Silicon (важно)

На M-чипах старые Intel-SMC-температурные ключи (`TC0P` и т.п.) не дают валидных значений,
поэтому реализованы два разных пути:

- **Температура** — приватный `IOHIDEventSystemClient` с фильтром по странице
  `AppleVendor` (0xff00) и usage температурных сенсоров (0x05). Читаются сенсоры
  CPU-кластеров (`PMU tdie*`, `PMU TP*` и т.п.), агрегируются в одно значение.
- **Вентиляторы** — AppleSMC через IOKit (`IOConnectCallStructMethod`), ключи
  `FNum`, `F%dAc`, `F%dMn`, `F%dMx`. Эти ключи на Apple Silicon остаются валидными.

> **Почему SMC-чтение вынесено в Objective-C/C:** структура запроса к ядру (`SMCParamStruct`,
> 80 байт) должна иметь точную C-раскладку полей. Swift не гарантирует layout структур и
> переупаковывает поля (получали 76 байт → `kIOReturnBadArgument`). Поэтому низкоуровневый
> вызов сделан на C, где раскладка детерминирована.

### Ограничения и мягкая деградация

- **Без `sudo`.** `powermetrics` (требует root) не используется.
- Если сенсор недоступен — в UI показывается «—», приложение не падает.
- **MacBook Air** и некоторые модели **без активных вентиляторов** — это норма, не баг:
  список вентиляторов пуст, строка показывает «—».
- При первом опросе в консоль выводится список всех найденных температурных сенсоров —
  удобно для отладки на конкретной модели чипа.
- Проверено на **MacBook Pro M1 Pro**: 2 вентилятора, температура CPU читается.

## App Sandbox и подпись

- **Sandbox выключен** (`com.apple.security.app-sandbox = false`): чтение SMC/HID-сенсоров
  недоступно из песочницы. Для локального инструмента это допустимо.
- Последствие: приложение в таком виде **нельзя распространять через Mac App Store**.
  Для распространения вне App Store потребуется Developer ID-подпись и нотаризация.
- Для локального запуска достаточно ad-hoc/dev-подписи (выставляется Xcode автоматически).

## Лицензия

Личный проект. Используйте на своё усмотрение.
