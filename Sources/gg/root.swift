import Guaka

var rootCommand = Command(
  usage: "gg", configuration: configuration, run: execute)

private func configuration(command: Command) {

  let version = Flag(shortName: "v", longName: "version", value: false, description: "Prints the version")

  command.add(flags: [
      version
    ]
  )

  // Other configurations
}

private func execute(flags: Flags, args: [String]) {
  // Execute code here
  if let version = flags.getBool(name: "version"), version {
    print("Version 0.0.1")
  } else {
    // Error happened
    rootCommand.fail(statusCode: 1, errorMessage: "Some error happaned")
  }
}
