@inline(__always)
func mockSynValidateMatcherCount(
    builder: Any.Type,
    expected: Int,
    actual: Int
) {
    precondition(
        actual == expected,
        "\(String(reflecting: builder)) expected \(expected) matcher(s), received \(actual)."
    )
}

@inline(__always)
func mockSynTypedArgument<Argument>(
    _ arguments: [Any],
    at index: Int,
    as _: Argument.Type,
    builder: Any.Type
) -> Argument {
    precondition(
        arguments.indices.contains(index),
        "\(String(reflecting: builder)) expected argument at index \(index), received \(arguments.count) argument(s)."
    )

    guard let argument = arguments[index] as? Argument else {
        preconditionFailure(
            "\(String(reflecting: builder)) expected argument at index \(index) to be "
                + "\(String(reflecting: Argument.self)), received "
                + "\(String(reflecting: Swift.type(of: arguments[index])))."
        )
    }

    return argument
}

@inline(__always)
func mockSynLastTypedArgument<Argument>(
    _ arguments: [Any],
    as _: Argument.Type,
    builder: Any.Type
) -> Argument {
    precondition(
        !arguments.isEmpty,
        "\(String(reflecting: builder)) expected at least 1 argument, received 0."
    )
    return mockSynTypedArgument(
        arguments,
        at: arguments.count - 1,
        as: Argument.self,
        builder: builder
    )
}
