import Foundation

/// Sorteio diário sem estado: a cada ciclo de `count` dias, uma permutação de 0..<count
/// (semeada por installID + salt + ciclo) define a ordem. Zero repetição dentro do ciclo.
enum DailyPicker {
    /// Índice do item do dia, em 0..<count. Retorna 0 se `count <= 1`.
    static func index(count: Int, installID: String, salt: String, day: DayKey) -> Int {
        guard count > 1 else { return 0 }
        let number = day.dayNumber
        let cycle = floorDivide(number, by: count)
        let position = number - cycle * count
        return permutation(count: count, installID: installID, salt: salt, cycle: cycle)[position]
    }

    /// Permutação de 0..<count do ciclo, via Fisher–Yates com SplitMix64.
    /// O índice aleatório é `next() % (i + 1)` (explícito, para não depender do algoritmo
    /// interno de `Int.random(in:using:)`, que a Apple pode mudar entre versões do Swift).
    static func permutation(count: Int, installID: String, salt: String, cycle: Int) -> [Int] {
        var order = Array(0..<max(count, 0))
        guard order.count > 1 else { return order }
        var generator = SeededGenerator(seed: StableHash.fnv1a64("\(installID)|\(salt)|ciclo\(cycle)"))
        var i = order.count - 1
        while i > 0 {
            let j = Int(generator.next() % UInt64(i + 1))
            order.swapAt(i, j)
            i -= 1
        }
        return order
    }

    /// Divisão com arredondamento para baixo (correta para dias negativos).
    private static func floorDivide(_ a: Int, by b: Int) -> Int {
        let quotient = a / b
        return (a % b != 0 && a < 0) ? quotient - 1 : quotient
    }
}
