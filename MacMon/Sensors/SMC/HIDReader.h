//
//  HIDReader.h
//  Тонкая Objective-C обёртка над приватным IOHID Event System для чтения
//  температурных сенсоров на Apple Silicon (без sudo). Возвращает массив
//  словарей @{ @"name": NSString, @"value": NSNumber(°C) }.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HIDReader : NSObject

/// Снимок всех доступных температурных сенсоров. Пустой массив, если их нет.
- (NSArray<NSDictionary<NSString *, id> *> *)readTemperatures;

@end

NS_ASSUME_NONNULL_END
