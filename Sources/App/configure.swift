import Fluent
import FluentPostgresDriver
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    let postgresConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "username",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "database",
        tls: try makeTlsConfiguration()
    )

    app.databases.use(.postgres(
        configuration: postgresConfig,
        sqlLogLevel: .warning
    ), as: .psql)

    func makeTlsConfiguration() throws -> PostgresConnection.Configuration.TLS {
        guard let certPath = Environment.get("DATABASE_SSL_CERT_PATH") else {
            // If no certificate path is provided, use the default settings which typically do not enforce TLS
            return .disable
        }
        
        // Load the certificate
        let certificates = try NIOSSLCertificate.fromPEMFile(certPath)
        
        // Create a TLS configuration
        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        tlsConfiguration.trustRoots = .certificates(certificates)  // This expects an array of NIOSSLCertificate
        
        // Optionally, if you need to present this certificate as a client certificate:
        tlsConfiguration.certificateChain = certificates.map { .certificate($0) }  // Map each certificate to the required type
        
        // Create an SSL context with the configured TLS settings
        let sslContext = try NIOSSLContext(configuration: tlsConfiguration)
        
        // Choose to require TLS connections
        return .require(sslContext)
    }
    
    // Migrations
    app.migrations.add(CreateUserTableMigration())
    app.migrations.add(CreateGymTableMigration())
    app.migrations.add(AddCityAndCountryToGymTableMigration())
    app.migrations.add(CreateTokenTableMigration())
    
    try await app.autoMigrate()
    
    // Register routes
    try routes(app)
}
