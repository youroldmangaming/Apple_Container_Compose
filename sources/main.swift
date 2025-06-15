import Foundation
import Yams

// MARK: - Codable Structs for docker-compose.yml
// These structs define the structure of the docker-compose.yml file
// allowing it to be decoded from YAML into Swift objects.

/// Represents the top-level structure of a docker-compose.yml file.
struct DockerCompose: Codable {
    let version: String? // The Compose file format version (e.g., '3.8')
    let name: String? // Optional project name
    let services: [String: Service] // Dictionary of service definitions, keyed by service name
    let volumes: [String: Volume]? // Optional top-level volume definitions
    let networks: [String: Network]? // Optional top-level network definitions
    let configs: [String: Config]? // Optional top-level config definitions (primarily for Swarm)
    let secrets: [String: Secret]? // Optional top-level secret definitions (primarily for Swarm)
}

/// Represents a single service definition within the `services` section.
struct Service: Codable {
    let image: String? // Docker image name
    let build: Build? // Build configuration if the service is built from a Dockerfile
    let deploy: Deploy? // Deployment configuration (primarily for Swarm)
    let restart: String? // Restart policy (e.g., 'unless-stopped', 'always')
    let healthcheck: Healthcheck? // Healthcheck configuration
    let volumes: [String]? // List of volume mounts (e.g., "hostPath:containerPath", "namedVolume:/path")
    let environment: [String: String]? // Environment variables to set in the container
    let env_file: [String]? // List of .env files to load environment variables from
    let ports: [String]? // Port mappings (e.g., "hostPort:containerPort")
    let command: [String]? // Command to execute in the container, overriding the image's default
    let depends_on: [String]? // Services this service depends on (for startup order)
    let user: String? // User or UID to run the container as

    let container_name: String? // Explicit name for the container instance
    let networks: [String]? // List of networks the service will connect to
    let hostname: String? // Container hostname
    let entrypoint: [String]? // Entrypoint to execute in the container, overriding the image's default
    let privileged: Bool? // Run container in privileged mode
    let read_only: Bool? // Mount container's root filesystem as read-only
    let working_dir: String? // Working directory inside the container
    let configs: [ServiceConfig]? // Service-specific config usage (primarily for Swarm)
    let secrets: [ServiceSecret]? // Service-specific secret usage (primarily for Swarm)
    let stdin_open: Bool? // Keep STDIN open (-i flag for `container run`)
    let tty: Bool? // Allocate a pseudo-TTY (-t flag for `container run`)
    
    // Defines custom coding keys to map YAML keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case image, build, deploy, restart, healthcheck, volumes, environment, env_file, ports, command, depends_on, user,
             container_name, networks, hostname, entrypoint, privileged, read_only, working_dir, configs, secrets, stdin_open, tty
    }

    /// Custom initializer to handle decoding and basic validation.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        build = try container.decodeIfPresent(Build.self, forKey: .build)
        deploy = try container.decodeIfPresent(Deploy.self, forKey: .deploy)
        
        // Ensure that a service has either an image or a build context.
        guard image != nil || build != nil else {
            throw DecodingError.dataCorruptedError(forKey: .image, in: container, debugDescription: "Service must have either 'image' or 'build' specified.")
        }

        restart = try container.decodeIfPresent(String.self, forKey: .restart)
        healthcheck = try container.decodeIfPresent(Healthcheck.self, forKey: .healthcheck)
        volumes = try container.decodeIfPresent([String].self, forKey: .volumes)
        environment = try container.decodeIfPresent([String: String].self, forKey: .environment)
        env_file = try container.decodeIfPresent([String].self, forKey: .env_file)
        ports = try container.decodeIfPresent([String].self, forKey: .ports)

        // Decode 'command' which can be either a single string or an array of strings.
        if let cmdArray = try? container.decodeIfPresent([String].self, forKey: .command) {
            command = cmdArray
        } else if let cmdString = try? container.decodeIfPresent(String.self, forKey: .command) {
            command = [cmdString]
        } else {
            command = nil
        }
        
        depends_on = try container.decodeIfPresent([String].self, forKey: .depends_on)
        user = try container.decodeIfPresent(String.self, forKey: .user)

        container_name = try container.decodeIfPresent(String.self, forKey: .container_name)
        networks = try container.decodeIfPresent([String].self, forKey: .networks)
        hostname = try container.decodeIfPresent(String.self, forKey: .hostname)
        
        // Decode 'entrypoint' which can be either a single string or an array of strings.
        if let entrypointArray = try? container.decodeIfPresent([String].self, forKey: .entrypoint) {
            entrypoint = entrypointArray
        } else if let entrypointString = try? container.decodeIfPresent(String.self, forKey: .entrypoint) {
            entrypoint = [entrypointString]
        } else {
            entrypoint = nil
        }

        privileged = try container.decodeIfPresent(Bool.self, forKey: .privileged)
        read_only = try container.decodeIfPresent(Bool.self, forKey: .read_only)
        working_dir = try container.decodeIfPresent(String.self, forKey: .working_dir)
        configs = try container.decodeIfPresent([ServiceConfig].self, forKey: .configs)
        secrets = try container.decodeIfPresent([ServiceSecret].self, forKey: .secrets)
        stdin_open = try container.decodeIfPresent(Bool.self, forKey: .stdin_open)
        tty = try container.decodeIfPresent(Bool.self, forKey: .tty)
    }
}

/// Represents the `build` configuration for a service.
struct Build: Codable {
    let context: String // Path to the build context
    let dockerfile: String? // Optional path to the Dockerfile within the context
    let args: [String: String]? // Build arguments
    
    // Custom initializer to handle `build: .` (string) or `build: { context: . }` (object)
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let contextString = try? container.decode(String.self) {
            self.context = contextString
            self.dockerfile = nil
            self.args = nil
        } else {
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.context = try keyedContainer.decode(String.self, forKey: .context)
            self.dockerfile = try keyedContainer.decodeIfPresent(String.self, forKey: .dockerfile)
            self.args = try keyedContainer.decodeIfPresent([String: String].self, forKey: .args)
        }
    }

    enum CodingKeys: String, CodingKey {
        case context, dockerfile, args
    }
}

/// Represents the `deploy` configuration for a service (primarily for Swarm orchestration).
struct Deploy: Codable {
    let mode: String? // Deployment mode (e.g., 'replicated', 'global')
    let replicas: Int? // Number of replicated service tasks
    let resources: DeployResources? // Resource constraints (limits, reservations)
    let restart_policy: DeployRestartPolicy? // Restart policy for tasks
}

/// Resource constraints for deployment.
struct DeployResources: Codable {
    let limits: ResourceLimits? // Hard limits on resources
    let reservations: ResourceReservations? // Guarantees for resources
}

/// CPU and memory limits.
struct ResourceLimits: Codable {
    let cpus: String? // CPU limit (e.g., "0.5")
    let memory: String? // Memory limit (e.g., "512M")
}

/// **FIXED**: Renamed from `ResourceReservables` to `ResourceReservations` and made `Codable`.
/// CPU and memory reservations.
struct ResourceReservations: Codable { // Changed from ResourceReservables to ResourceReservations
    let cpus: String? // CPU reservation (e.g., "0.25")
    let memory: String? // Memory reservation (e.g., "256M")
    let devices: [DeviceReservation]? // Device reservations for GPUs or other devices
}

/// Device reservations for GPUs or other devices.
struct DeviceReservation: Codable {
    let capabilities: [String]? // Device capabilities
    let driver: String? // Device driver
    let count: String? // Number of devices
    let device_ids: [String]? // Specific device IDs
}

/// Restart policy for deployed tasks.
struct DeployRestartPolicy: Codable {
    let condition: String? // Condition to restart on (e.g., 'on-failure', 'any')
    let delay: String? // Delay before attempting restart
    let max_attempts: Int? // Maximum number of restart attempts
    let window: String? // Window to evaluate restart policy
}

/// Healthcheck configuration for a service.
struct Healthcheck: Codable {
    let test: [String]? // Command to run to check health
    let start_period: String? // Grace period for the container to start
    let interval: String? // How often to run the check
    let retries: Int? // Number of consecutive failures to consider unhealthy
    let timeout: String? // Timeout for each check
}

/// Represents a top-level volume definition.
struct Volume: Codable {
    let driver: String? // Volume driver (e.g., 'local')
    let driver_opts: [String: String]? // Driver-specific options
    let name: String? // Explicit name for the volume
    let labels: [String: String]? // Labels for the volume
    let external: ExternalVolume? // Indicates if the volume is external (pre-existing)

    enum CodingKeys: String, CodingKey {
        case driver, driver_opts, name, labels, external
    }

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_vol" }` (object).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        driver = try container.decodeIfPresent(String.self, forKey: .driver)
        driver_opts = try container.decodeIfPresent([String: String].self, forKey: .driver_opts)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        labels = try container.decodeIfPresent([String: String].self, forKey: .labels)

        if let externalBool = try? container.decodeIfPresent(Bool.self, forKey: .external) {
            external = ExternalVolume(isExternal: externalBool, name: nil)
        } else if let externalDict = try? container.decodeIfPresent([String: String].self, forKey: .external) {
            external = ExternalVolume(isExternal: true, name: externalDict["name"])
        } else {
            external = nil
        }
    }
}

/// Represents an external volume reference.
struct ExternalVolume: Codable {
    let isExternal: Bool // True if the volume is external
    let name: String? // Optional name of the external volume if different from key
}

/// Represents a top-level network definition.
struct Network: Codable {
    let driver: String? // Network driver (e.g., 'bridge', 'overlay')
    let driver_opts: [String: String]? // Driver-specific options
    let attachable: Bool? // Allow standalone containers to attach to this network
    let enable_ipv6: Bool? // Enable IPv6 networking
    let isInternal: Bool? // RENAMED: from `internal` to `isInternal` to avoid keyword clash
    let labels: [String: String]? // Labels for the network
    let name: String? // Explicit name for the network
    let external: ExternalNetwork? // Indicates if the network is external (pre-existing)

    // Updated CodingKeys to map 'internal' from YAML to 'isInternal' Swift property
    enum CodingKeys: String, CodingKey {
        case driver, driver_opts, attachable, enable_ipv6, isInternal = "internal", labels, name, external
    }

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_net" }` (object).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        driver = try container.decodeIfPresent(String.self, forKey: .driver)
        driver_opts = try container.decodeIfPresent([String: String].self, forKey: .driver_opts)
        attachable = try container.decodeIfPresent(Bool.self, forKey: .attachable)
        enable_ipv6 = try container.decodeIfPresent(Bool.self, forKey: .enable_ipv6)
        isInternal = try container.decodeIfPresent(Bool.self, forKey: .isInternal) // Use isInternal here
        labels = try container.decodeIfPresent([String: String].self, forKey: .labels)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        if let externalBool = try? container.decodeIfPresent(Bool.self, forKey: .external) {
            external = ExternalNetwork(isExternal: externalBool, name: nil)
        } else if let externalDict = try? container.decodeIfPresent([String: String].self, forKey: .external) {
            external = ExternalNetwork(isExternal: true, name: externalDict["name"])
        } else {
            external = nil
        }
    }
}

/// Represents an external network reference.
struct ExternalNetwork: Codable {
    let isExternal: Bool // True if the network is external
    let name: String? // Optional name of the external network if different from key
}

/// Represents a top-level config definition (primarily for Swarm).
struct Config: Codable {
    let file: String? // Path to the file containing the config content
    let external: ExternalConfig? // Indicates if the config is external (pre-existing)
    let name: String? // Explicit name for the config
    let labels: [String: String]? // Labels for the config

    enum CodingKeys: String, CodingKey {
        case file, external, name, labels
    }

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_cfg" }` (object).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decodeIfPresent(String.self, forKey: .file)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        labels = try container.decodeIfPresent([String: String].self, forKey: .labels)

        if let externalBool = try? container.decodeIfPresent(Bool.self, forKey: .external) {
            external = ExternalConfig(isExternal: externalBool, name: nil)
        } else if let externalDict = try? container.decodeIfPresent([String: String].self, forKey: .external) {
            external = ExternalConfig(isExternal: true, name: externalDict["name"])
        } else {
            external = nil
        }
    }
}

/// Represents an external config reference.
struct ExternalConfig: Codable {
    let isExternal: Bool // True if the config is external
    let name: String? // Optional name of the external config if different from key
}

/// Represents a service's usage of a config.
struct ServiceConfig: Codable {
    let source: String // Name of the config being used
    let target: String? // Path in the container where the config will be mounted
    let uid: String? // User ID for the mounted config file
    let gid: String? // Group ID for the mounted config file
    let mode: Int? // Permissions mode for the mounted config file

    /// Custom initializer to handle `config_name` (string) or `{ source: config_name, target: /path }` (object).
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let sourceName = try? container.decode(String.self) {
            self.source = sourceName
            self.target = nil
            self.uid = nil
            self.gid = nil
            self.mode = nil
        } else {
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.source = try keyedContainer.decode(String.self, forKey: .source)
            self.target = try keyedContainer.decodeIfPresent(String.self, forKey: .target)
            self.uid = try keyedContainer.decodeIfPresent(String.self, forKey: .uid)
            self.gid = try keyedContainer.decodeIfPresent(String.self, forKey: .gid)
            self.mode = try keyedContainer.decodeIfPresent(Int.self, forKey: .mode)
        }
    }

    enum CodingKeys: String, CodingKey {
        case source, target, uid, gid, mode
    }
}


/// Represents a top-level secret definition (primarily for Swarm).
struct Secret: Codable {
    let file: String? // Path to the file containing the secret content
    let environment: String? // Environment variable to populate with the secret content
    let external: ExternalSecret? // Indicates if the secret is external (pre-existing)
    let name: String? // Explicit name for the secret
    let labels: [String: String]? // Labels for the secret

    enum CodingKeys: String, CodingKey {
        case file, environment, external, name, labels
    }

    /// Custom initializer to handle `external: true` (boolean) or `external: { name: "my_sec" }` (object).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        file = try container.decodeIfPresent(String.self, forKey: .file)
        environment = try container.decodeIfPresent(String.self, forKey: .environment)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        labels = try container.decodeIfPresent([String: String].self, forKey: .labels)

        if let externalBool = try? container.decodeIfPresent(Bool.self, forKey: .external) {
            external = ExternalSecret(isExternal: externalBool, name: nil)
        } else if let externalDict = try? container.decodeIfPresent([String: String].self, forKey: .external) {
            external = ExternalSecret(isExternal: true, name: externalDict["name"])
        } else {
            external = nil
        }
    }
}

/// Represents an external secret reference.
struct ExternalSecret: Codable {
    let isExternal: Bool // True if the secret is external
    let name: String? // Optional name of the external secret if different from key
}

/// Represents a service's usage of a secret.
struct ServiceSecret: Codable {
    let source: String // Name of the secret being used
    let target: String? // Path in the container where the secret will be mounted
    let uid: String? // User ID for the mounted secret file
    let gid: String? // Group ID for the mounted secret file
    let mode: Int? // Permissions mode for the mounted secret file

    /// Custom initializer to handle `secret_name` (string) or `{ source: secret_name, target: /path }` (object).
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let sourceName = try? container.decode(String.self) {
            self.source = sourceName
            self.target = nil
            self.uid = nil
            self.gid = nil
            self.mode = nil
        } else {
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.source = try keyedContainer.decode(String.self, forKey: .source)
            self.target = try keyedContainer.decodeIfPresent(String.self, forKey: .target)
            self.uid = try keyedContainer.decodeIfPresent(String.self, forKey: .uid)
            self.gid = try keyedContainer.decodeIfPresent(String.self, forKey: .gid)
            self.mode = try keyedContainer.decodeIfPresent(Int.self, forKey: .mode)
        }
    }

    enum CodingKeys: String, CodingKey {
        case source, target, uid, gid, mode
    }
}


// MARK: - Helper Functions

/// Loads environment variables from a .env file.
/// - Parameter path: The full path to the .env file.
/// - Returns: A dictionary of key-value pairs representing environment variables.
func loadEnvFile(path: String) -> [String: String] {
    var envVars: [String: String] = [:]
    let fileURL = URL(fileURLWithPath: path)
    do {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.split(separator: "\n")
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Ignore empty lines and comments
            if !trimmedLine.isEmpty && !trimmedLine.starts(with: "#") {
                // Parse key=value pairs
                if let eqIndex = trimmedLine.firstIndex(of: "=") {
                    let key = String(trimmedLine[..<eqIndex])
                    let value = String(trimmedLine[trimmedLine.index(after: eqIndex)...])
                    envVars[key] = value
                }
            }
        }
    } catch {
        // print("Warning: Could not read .env file at \(path): \(error.localizedDescription)")
        // Suppress error message if .env file is optional or missing
    }
    return envVars
}

/// Resolves environment variables within a string (e.g., ${VAR:-default}, ${VAR:?error}).
/// This function supports default values and error-on-missing variable syntax.
/// - Parameters:
///   - value: The string possibly containing environment variable references.
///   - envVars: A dictionary of environment variables to use for resolution.
/// - Returns: The string with all recognized environment variables resolved.
func resolveVariable(_ value: String, with envVars: [String: String]) -> String {
    var resolvedValue = value
    // Regex to find ${VAR}, ${VAR:-default}, ${VAR:?error}
    let regex = try! NSRegularExpression(pattern: "\\$\\{([A-Z0-9_]+)(:?-(.*?))?(:\\?(.*?))?\\}", options: [])
    
    // Combine process environment with loaded .env file variables, prioritizing process environment
    let combinedEnv = ProcessInfo.processInfo.environment.merging(envVars) { (current, _) in current }

    // Loop to resolve all occurrences of variables in the string
    while let match = regex.firstMatch(in: resolvedValue, options: [], range: NSRange(resolvedValue.startIndex..<resolvedValue.endIndex, in: resolvedValue)) {
        guard let varNameRange = Range(match.range(at: 1), in: resolvedValue) else { break }
        let varName = String(resolvedValue[varNameRange])
        
        if let envValue = combinedEnv[varName] {
            // Variable found in environment, replace with its value
            resolvedValue.replaceSubrange(Range(match.range(at: 0), in: resolvedValue)!, with: envValue)
        } else if let defaultValueRange = Range(match.range(at: 3), in: resolvedValue) {
            // Variable not found, but default value is provided, replace with default
            let defaultValue = String(resolvedValue[defaultValueRange])
            resolvedValue.replaceSubrange(Range(match.range(at: 0), in: resolvedValue)!, with: defaultValue)
        } else if match.range(at: 5).location != NSNotFound, let errorMessageRange = Range(match.range(at: 5), in: resolvedValue) {
            // Variable not found, and error-on-missing syntax used, print error and exit
            let errorMessage = String(resolvedValue[errorMessageRange])
            fputs("Error: Missing required environment variable '\(varName)': \(errorMessage)\n", stderr)
            exit(1)
        } else {
            // Variable not found and no default/error specified, leave as is and break loop to avoid infinite loop
            break
        }
    }
    return resolvedValue
}


/// Executes an external command using `/usr/bin/env`.
/// - Parameters:
///   - command: The primary command to execute (e.g., "container").
///   - arguments: An array of arguments for the command.
///   - detach: A boolean indicating if the command should be run in a detached mode (for logging purposes here).
func executeCommand(command: String, arguments: [String], detach: Bool) {
    let process = Process()
    process.launchPath = "/usr/bin/env" // Use env to ensure command is found in PATH
    process.arguments = [command] + arguments

    let outputPipe = Pipe()
    let errorPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = errorPipe

    do {
        try process.run() // Start the process
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        // Print captured stdout and stderr
        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            print("Container stdout: \(output)")
        }
        if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
            fputs("Container stderr: \(error)\n", stderr)
        }

        process.waitUntilExit() // Wait for the process to complete

        // Check for non-zero exit status
        if process.terminationStatus != 0 {
            fputs("Error: Command '\(command) \(arguments.joined(separator: " "))' exited with status \(process.terminationStatus)\n", stderr)
        }

    } catch {
        fputs("Error executing command '\(command) \(arguments.joined(separator: " "))': \(error.localizedDescription)\n", stderr)
        exit(1) // Exit if command execution fails
    }
}

// MARK: - Main Logic

// Process command line arguments
let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("Usage: \(arguments[0]) up [-d]")
    exit(1)
}

let subcommand = arguments[1] // Get the subcommand (e.g., "up")
let detachFlag = arguments.contains("-d") // Check for the -d (detach) flag

// Currently, only the "up" subcommand is supported
guard subcommand == "up" else {
    print("Error: Only 'up' subcommand is supported.")
    exit(1)
}

let fileManager = FileManager.default
let currentDirectory = fileManager.currentDirectoryPath // Get current working directory
let dockerComposePath = "\(currentDirectory)/docker-compose.yml" // Path to docker-compose.yml
let envFilePath = "\(currentDirectory)/.env" // Path to optional .env file

// Read docker-compose.yml content
guard let yamlData = fileManager.contents(atPath: dockerComposePath) else {
    fputs("Error: docker-compose.yml not found at \(dockerComposePath)\n", stderr)
    exit(1)
}

do {
    // Decode the YAML file into the DockerCompose struct
    let dockerComposeString = String(data: yamlData, encoding: .utf8)!
    let dockerCompose = try YAMLDecoder().decode(DockerCompose.self, from: dockerComposeString)

    // Load environment variables from .env file
    let envVarsFromFile = loadEnvFile(path: envFilePath)

    // Handle 'version' field
    if let version = dockerCompose.version {
        print("Info: Docker Compose file version parsed as: \(version)")
        print("Note: The 'version' field influences how a Docker Compose CLI interprets the file, but this custom 'container-compose' tool directly interprets the schema.")
    }

    // Determine project name for container naming
    var projectName: String? = nil
    if let name = dockerCompose.name {
        projectName = name
        print("Info: Docker Compose project name parsed as: \(name)")
        print("Note: The 'name' field currently only affects container naming (e.g., '\(name)-serviceName'). Full project-level isolation for other resources (networks, implicit volumes) is not implemented by this tool.")
    } else {
        projectName = URL(fileURLWithPath: currentDirectory).lastPathComponent // Default to directory name
        print("Info: No 'name' field found in docker-compose.yml. Using directory name as project name: \(projectName ?? "unknown")")
    }

    // Process top-level networks
    // This creates named networks defined in the docker-compose.yml
    if let networks = dockerCompose.networks {
        print("\n--- Processing Networks ---")
        for (networkName, networkConfig) in networks {
            let actualNetworkName = networkConfig.name ?? networkName // Use explicit name or key as name

            if let externalNetwork = networkConfig.external, externalNetwork.isExternal {
                print("Info: Network '\(networkName)' is declared as external.")
                print("This tool assumes external network '\(externalNetwork.name ?? actualNetworkName)' already exists and will not attempt to create it.")
            } else {
                var networkCreateArgs: [String] = ["network", "create"]

                // Add driver and driver options
                if let driver = networkConfig.driver {
                    networkCreateArgs.append("--driver")
                    networkCreateArgs.append(driver)
                }
                if let driverOpts = networkConfig.driver_opts {
                    for (optKey, optValue) in driverOpts {
                        networkCreateArgs.append("--opt")
                        networkCreateArgs.append("\(optKey)=\(optValue)")
                    }
                }
                // Add various network flags
                if networkConfig.attachable == true { networkCreateArgs.append("--attachable") }
                if networkConfig.enable_ipv6 == true { networkCreateArgs.append("--ipv6") }
                if networkConfig.isInternal == true { networkCreateArgs.append("--internal") } // CORRECTED: Use isInternal
                
                // Add labels
                if let labels = networkConfig.labels {
                    for (labelKey, labelValue) in labels {
                        networkCreateArgs.append("--label")
                        networkCreateArgs.append("\(labelKey)=\(labelValue)")
                    }
                }

                networkCreateArgs.append(actualNetworkName) // Add the network name

                print("Creating network: \(networkName) (Actual name: \(actualNetworkName))")
                print("Executing container network create: container \(networkCreateArgs.joined(separator: " "))")
                executeCommand(command: "container", arguments: networkCreateArgs, detach: false)
                print("Network '\(networkName)' created or already exists.")
            }
        }
        print("--- Networks Processed ---\n")
    }

    // Process top-level volumes
    // This creates named volumes defined in the docker-compose.yml
    if let volumes = dockerCompose.volumes {
        print("\n--- Processing Volumes ---")
        for (volumeName, volumeConfig) in volumes {
            let actualVolumeName = volumeConfig.name ?? volumeName // Use explicit name or key as name

            if let externalVolume = volumeConfig.external, externalVolume.isExternal {
                print("Info: Volume '\(volumeName)' is declared as external.")
                print("This tool assumes external volume '\(externalVolume.name ?? actualVolumeName)' already exists and will not attempt to create it.")
            } else {
                var volumeCreateArgs: [String] = ["volume", "create"]

                // Add driver and driver options
                if let driver = volumeConfig.driver {
                    volumeCreateArgs.append("--driver")
                    volumeCreateArgs.append(driver)
                }
                if let driverOpts = volumeConfig.driver_opts {
                    for (optKey, optValue) in driverOpts {
                        volumeCreateArgs.append("--opt")
                        volumeCreateArgs.append("\(optKey)=\(optValue)")
                    }
                }
                // Add labels
                if let labels = volumeConfig.labels {
                    for (labelKey, labelValue) in labels {
                        volumeCreateArgs.append("--label")
                        volumeCreateArgs.append("\(labelKey)=\(labelValue)")
                    }
                }

                volumeCreateArgs.append(actualVolumeName) // Add the volume name

                print("Creating volume: \(volumeName) (Actual name: \(actualVolumeName))")
                print("Executing container volume create: container \(volumeCreateArgs.joined(separator: " "))")
                executeCommand(command: "container", arguments: volumeCreateArgs, detach: false)
                print("Volume '\(volumeName)' created or already exists.")
            }
        }
        print("--- Volumes Processed ---\n")
    }

    // Process top-level configs
    // Note: Docker Compose 'configs' are primarily for Docker Swarm and are not directly managed by 'container run'.
    // The tool parses them but does not create or attach them.
    if let configs = dockerCompose.configs {
        print("\n--- Processing Configs ---")
        print("Note: Docker Compose 'configs' are primarily used for Docker Swarm deployed stacks and are not directly translatable to 'container run' commands.")
        print("This tool will parse 'configs' definitions but will not create or attach them to containers.")
        for (configName, configConfig) in configs {
            let actualConfigName = configConfig.name ?? configName
            if let externalConfig = configConfig.external, externalConfig.isExternal {
                print("Info: Config '\(configName)' is declared as external (actual name: \(externalConfig.name ?? actualConfigName)). This tool will not attempt to create or manage it.")
            } else if let file = configConfig.file {
                let resolvedFile = resolveVariable(file, with: envVarsFromFile)
                print("Info: Config '\(configName)' is defined from file '\(resolvedFile)'. This tool cannot automatically manage its distribution to individual containers outside of Swarm mode.")
            } else {
                print("Info: Config '\(configName)' (actual name: \(actualConfigName)) is defined. This tool cannot automatically manage its distribution to individual containers outside of Swarm mode.")
            }
        }
        print("--- Configs Processed ---\n")
    }
    
    // Process top-level secrets
    // Note: Docker Compose 'secrets' are primarily for Docker Swarm and are not directly managed by 'container run'.
    // The tool parses them but does not create or attach them.
    if let secrets = dockerCompose.secrets {
        print("\n--- Processing Secrets ---")
        print("Note: Docker Compose 'secrets' are primarily used for Docker Swarm deployed stacks and are not directly translatable to 'container run' commands.")
        print("This tool will parse 'secrets' definitions but will not create or attach them to containers.")
        for (secretName, secretConfig) in secrets {
            let actualSecretName = secretConfig.name ?? secretName // Define actualSecretName here
            if let externalSecret = secretConfig.external, externalSecret.isExternal {
                print("Info: Secret '\(secretName)' is declared as external (actual name: \(externalSecret.name ?? actualSecretName)). This tool will not attempt to create or manage it.")
            } else if let file = secretConfig.file {
                let resolvedFile = resolveVariable(file, with: envVarsFromFile)
                print("Info: Secret '\(secretName)' is defined from file '\(resolvedFile)'. This tool cannot automatically manage its distribution to individual containers outside of Swarm mode.")
            } else {
                print("Info: Secret '\(secretName)' (actual name: \(actualSecretName)) is defined. This tool cannot automatically manage its distribution to individual containers outside of Swarm mode.")
            }
        }
        print("--- Secrets Processed ---\n")
    }


    // Process each service defined in the docker-compose.yml
    print("\n--- Processing Services ---")
    for (serviceName, service) in dockerCompose.services {
        var imageToRun: String

        // Handle 'build' configuration
        if let buildConfig = service.build {
            var buildCommandArgs: [String] = ["build"]

            // Determine image tag for built image
            imageToRun = service.image ?? "\(serviceName):latest"

            buildCommandArgs.append("--tag")
            buildCommandArgs.append(imageToRun)

            // Resolve build context path
            let resolvedContext = resolveVariable(buildConfig.context, with: envVarsFromFile)
            buildCommandArgs.append(resolvedContext)

            // Add Dockerfile path if specified
            if let dockerfile = buildConfig.dockerfile {
                let resolvedDockerfile = resolveVariable(dockerfile, with: envVarsFromFile)
                buildCommandArgs.append("--file")
                buildCommandArgs.append(resolvedDockerfile)
            }

            // Add build arguments
            if let args = buildConfig.args {
                for (key, value) in args {
                    let resolvedValue = resolveVariable(value, with: envVarsFromFile)
                    buildCommandArgs.append("--build-arg")
                    buildCommandArgs.append("\(key)=\(resolvedValue)")
                }
            }
            
            print("\n----------------------------------------")
            print("Building image for service: \(serviceName) (Tag: \(imageToRun))")
            print("Executing container build: container \(buildCommandArgs.joined(separator: " "))")
            executeCommand(command: "container", arguments: buildCommandArgs, detach: false)
            print("Image build for \(serviceName) completed.")
            print("----------------------------------------")

        } else if let img = service.image {
            // Use specified image if no build config
            imageToRun = resolveVariable(img, with: envVarsFromFile)
        } else {
            // Should not happen due to Service init validation, but as a fallback
            fputs("Error: Service \(serviceName) must define either 'image' or 'build'. Skipping.\n", stderr)
            continue
        }

        // Handle 'deploy' configuration (note that this tool doesn't fully support it)
        if service.deploy != nil {
            print("Note: The 'deploy' configuration for service '\(serviceName)' was parsed successfully.")
            print("However, this 'container-compose' tool does not currently support 'deploy' functionality (e.g., replicas, resources, update strategies) as it is primarily for orchestration platforms like Docker Swarm or Kubernetes, not direct 'container run' commands.")
            print("The service will be run as a single container based on other configurations.")
        }

        var runCommandArgs: [String] = []

        // Add detach flag if specified on the CLI
        if detachFlag {
            runCommandArgs.append("-d")
        }

        // Determine container name
        let containerName: String
        if let explicitContainerName = service.container_name {
            containerName = explicitContainerName
            print("Info: Using explicit container_name: \(containerName)")
        } else {
            // Default container name based on project and service name
            containerName = (projectName != nil) ? "\(projectName!)-\(serviceName)" : serviceName
        }
        runCommandArgs.append("--name")
        runCommandArgs.append(containerName)

        // REMOVED: Restart policy is not supported by `container run`
        // if let restart = service.restart {
        //     runCommandArgs.append("--restart")
        //     runCommandArgs.append(restart)
        // }

        // Add user
        if let user = service.user {
            runCommandArgs.append("--user")
            runCommandArgs.append(user)
        }

        // Add volume mounts
        if let volumes = service.volumes {
            for volume in volumes {
                let resolvedVolume = resolveVariable(volume, with: envVarsFromFile)
                
                // Parse the volume string: destination[:mode]
                let components = resolvedVolume.split(separator: ":", maxSplits: 2).map(String.init)
                
                guard components.count >= 2 else {
                    print("Warning: Volume entry '\(resolvedVolume)' has an invalid format (expected 'source:destination'). Skipping.")
                    continue
                }

                let source = components[0]
                let destination = components[1]
                
                // Check if the source looks like a host path (contains '/' or starts with '.')
                // This heuristic helps distinguish bind mounts from named volume references.
                if source.contains("/") || source.starts(with: ".") || source.starts(with: "..") {
                    // This is likely a bind mount (local path to container path)
                    var isDirectory: ObjCBool = false
                    // Ensure the path is absolute or relative to the current directory for FileManager
                    let fullHostPath = (source.starts(with: "/") || source.starts(with: "~")) ? source : (currentDirectory + "/" + source)
                    
                    if fileManager.fileExists(atPath: fullHostPath, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            // Host path exists and is a directory, add the volume
                            runCommandArgs.append("-v")
                            // Reconstruct the volume string without mode, ensuring it's source:destination
                            runCommandArgs.append("\(source):\(destination)") // Use original source for command argument
                        } else {
                            // Host path exists but is a file
                            print("Warning: Volume mount source '\(source)' is a file. The 'container' tool does not support direct file mounts. Skipping this volume.")
                        }
                    } else {
                        // Host path does not exist, assume it's meant to be a directory and try to create it.
                        do {
                            try fileManager.createDirectory(atPath: fullHostPath, withIntermediateDirectories: true, attributes: nil)
                            print("Info: Created missing host directory for volume: \(fullHostPath)")
                            runCommandArgs.append("-v")
                            runCommandArgs.append("\(source):\(destination)") // Use original source for command argument
                        } catch {
                            print("Error: Could not create host directory '\(fullHostPath)' for volume '\(resolvedVolume)': \(error.localizedDescription). Skipping this volume.")
                        }
                    }
                } else {
                    // This likely refers to a named volume (e.g., 'database' or 'redis')
                    // The 'container run -v' command does not support named volume references for attachment.
                    print("Warning: Volume source '\(source)' appears to be a named volume reference. The 'container' tool does not support named volume references in 'container run -v' command. Skipping this volume.")
                }
            }
        }

        // Combine environment variables from .env files and service environment
        var combinedEnv: [String: String] = envVarsFromFile
        
        if let envFiles = service.env_file {
            for envFile in envFiles {
                let additionalEnvVars = loadEnvFile(path: "\(currentDirectory)/\(envFile)")
                combinedEnv.merge(additionalEnvVars) { (current, _) in current }
            }
        }

        if let serviceEnv = service.environment {
            combinedEnv.merge(serviceEnv) { (_, new) in new } // Service env overrides .env files
        }

        // Add environment variables to run command
        for (key, value) in combinedEnv {
            let resolvedValue = resolveVariable(value, with: combinedEnv)
            runCommandArgs.append("-e")
            runCommandArgs.append("\(key)=\(resolvedValue)")
        }

        // REMOVED: Port mappings (-p) are not supported by `container run`
        // if let ports = service.ports {
        //     for port in ports {
        //         let resolvedPort = resolveVariable(port, with: envVarsFromFile)
        //         runCommandArgs.append("-p")
        //         runCommandArgs.append(resolvedPort)
        //     }
        // }

        // Connect to specified networks
        if let serviceNetworks = service.networks {
            for network in serviceNetworks {
                let resolvedNetwork = resolveVariable(network, with: envVarsFromFile)
                // Use the explicit network name from top-level definition if available, otherwise resolved name
                let networkToConnect = dockerCompose.networks?[network]?.name ?? resolvedNetwork
                runCommandArgs.append("--network")
                runCommandArgs.append(networkToConnect)
            }
            print("Info: Service '\(serviceName)' is configured to connect to networks: \(serviceNetworks.joined(separator: ", ")) ascertained from networks attribute in docker-compose.yml.")
            print("Note: This tool assumes custom networks are defined at the top-level 'networks' key or are pre-existing. This tool does not create implicit networks for services if not explicitly defined at the top-level.")
        } else {
            print("Note: Service '\(serviceName)' is not explicitly connected to any networks. It will likely use the default bridge network.")
        }

        // Add hostname
        if let hostname = service.hostname {
            let resolvedHostname = resolveVariable(hostname, with: envVarsFromFile)
            runCommandArgs.append("--hostname")
            runCommandArgs.append(resolvedHostname)
        }

        // Add working directory
        if let workingDir = service.working_dir {
            let resolvedWorkingDir = resolveVariable(workingDir, with: envVarsFromFile)
            runCommandArgs.append("--workdir")
            runCommandArgs.append(resolvedWorkingDir)
        }

        // Add privileged flag
        if service.privileged == true {
            runCommandArgs.append("--privileged")
        }

        // Add read-only flag
        if service.read_only == true {
            runCommandArgs.append("--read-only")
        }
        
        // Handle service-level configs (note: still only parsing/logging, not attaching)
        if let serviceConfigs = service.configs {
            print("Note: Service '\(serviceName)' defines 'configs'. Docker Compose 'configs' are primarily used for Docker Swarm deployed stacks and are not directly translatable to 'container run' commands.")
            print("This tool will parse 'configs' definitions but will not create or attach them to containers during 'container run'.")
            for serviceConfig in serviceConfigs {
                print("  - Config: '\(serviceConfig.source)' (Target: \(serviceConfig.target ?? "default location"), UID: \(serviceConfig.uid ?? "default"), GID: \(serviceConfig.gid ?? "default"), Mode: \(serviceConfig.mode?.description ?? "default"))")
            }
        }

        // Handle service-level secrets (note: still only parsing/logging, not attaching)
        if let serviceSecrets = service.secrets {
            print("Note: Service '\(serviceName)' defines 'secrets'. Docker Compose 'secrets' are primarily used for Docker Swarm deployed stacks and are not directly translatable to 'container run' commands.")
            print("This tool will parse 'secrets' definitions but will not create or attach them to containers during 'container run'.")
            for serviceSecret in serviceSecrets {
                print("  - Secret: '\(serviceSecret.source)' (Target: \(serviceSecret.target ?? "default location"), UID: \(serviceSecret.uid ?? "default"), GID: \(serviceSecret.gid ?? "default"), Mode: \(serviceSecret.mode?.description ?? "default"))")
            }
        }

        // Add interactive and TTY flags
        if service.stdin_open == true {
            runCommandArgs.append("-i") // --interactive
        }
        if service.tty == true {
            runCommandArgs.append("-t") // --tty
        }

        runCommandArgs.append(imageToRun) // Add the image name as the final argument before command/entrypoint

        // Add entrypoint or command
        if let entrypointParts = service.entrypoint {
            runCommandArgs.append("--entrypoint")
            runCommandArgs.append(contentsOf: entrypointParts)
        } else if let commandParts = service.command {
            runCommandArgs.append(contentsOf: commandParts)
        }
        
        print("\nStarting service: \(serviceName)")
        print("Executing container run: container run \(runCommandArgs.joined(separator: " "))")
        executeCommand(command: "container", arguments: ["run"] + runCommandArgs, detach: detachFlag)
        print("Service \(serviceName) command execution initiated.")
        print("----------------------------------------\n")
    }

} catch {
    fputs("Error parsing docker-compose.yml: \(error)\n", stderr)
    exit(1)
}
