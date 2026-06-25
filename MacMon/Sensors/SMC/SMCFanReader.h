//
//  SMCFanReader.h
//  Чтение оборотов вентиляторов через AppleSMC (IOKit). На Apple Silicon ключи
//  FNum / F%dAc / F%dMn / F%dMx остаются валидными. Реализация на C — чтобы layout
//  структуры SMC точно совпадал с ядром (Swift не гарантирует C-раскладку полей).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SMCFanReader : NSObject

/// Открыть соединение с AppleSMC. Возвращает YES при успехе.
- (BOOL)open;
- (void)close;

/// Массив @{ @"current": NSNumber, @"min": NSNumber, @"max": NSNumber } по каждому вентилятору.
/// Пустой массив — если вентиляторов нет (норма для MacBook Air) или SMC недоступен.
- (NSArray<NSDictionary<NSString *, NSNumber *> *> *)readFans;

@end

NS_ASSUME_NONNULL_END
