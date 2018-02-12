import Guaka
import Foundation

var githubCommand = Command(
  usage: "github", configuration: configuration, run: execute)

private func configuration(command: Command) {
  let user = Flag(shortName: "u", longName: "user", value: "none", description: "User login")
  let pass = Flag(shortName: "p", longName: "password", value: "none", description: "Passord login")
  let repo = Flag(shortName: "r", longName: "repository", value: "none", description: "Repository for digest")
  let mod = Flag(shortName: "m", longName: "modifier", value: "1Day", description: "Digest modifier")
  let branch = Flag(shortName: "b", longName: "branch", value: "master", description: "Branch Repository")

  command.add(flags: [
      user, pass, repo, mod, branch
    ]
  )
}

private func execute(flags: Flags, args: [String]) {
  let mod = flags.getString(name: "modifier") ?? "1Day"
  let branch = flags.getString(name: "branch") ?? "master"

  // Execute code here
  if let user = flags.getString(name: "user"),
    let pass = flags.getString(name: "password"),
    let repo = flags.getString(name: "repository") {
      getDigest(user: user, pass: pass, repo: repo, mod: mod, branch: branch)
  } else {
    // Error happened
    rootCommand.fail(statusCode: 1, errorMessage: "Some error happaned")
  }
}

private func getDigest(user: String, pass: String, repo: String, mod: String, branch: String) {
  let urlSession = URLSession(configuration: .ephemeral)

  let semaphore = DispatchSemaphore(value: 0)

  let authorizationRawString = "\(user):\(pass)"

  if let url = URL(string: "https://api.github.com/repos/\(repo)/compare/\(branch)%40%7B\(mod)%7D...\(branch)"),
    let authorizationEncoded = authorizationRawString.data(using: String.Encoding.ascii) {
      let encodedBase64 = authorizationEncoded.base64EncodedString(options: .endLineWithLineFeed)
      let authorizationValue = "Basic \(encodedBase64)"

      var request = URLRequest(url: url)

      request.setValue(authorizationValue, forHTTPHeaderField: "Authorization")

      let task = urlSession.dataTask(with: request,
                        completionHandler: completionHandler(semaphore: semaphore))

      task.resume()
  }

  _ = semaphore.wait(timeout: .distantFuture)
}

private func completionHandler(semaphore: DispatchSemaphore) -> ((Data?, URLResponse?, Error?) -> Void) {
  return { data, _, error in
    if let error = error {
        print("Encounter error: \(error)")
    } else if let data = data,
      let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
      let commits = jsonObject?["commits"] as? [[String: Any]] {
        commits.forEach({
          if let commit = $0["commit"] as? [String: Any],
            let message = commit["message"] as? String {
              print("\(message.components(separatedBy: "\n\n")[0])")
          }
        })
    }

    semaphore.signal()
  }
}
