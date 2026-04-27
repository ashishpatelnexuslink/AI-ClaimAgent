using System.Text.Json.Serialization;
using ClaimAI.API.Extensions;
using ClaimAI.API.Filters;
using ClaimAI.API.Middleware;
using ClaimAI.Application;
using ClaimAI.Infrastructure;
using ClaimAI.Infrastructure.Data.Seeders;
using ClaimAI.Infrastructure.Identity;
using Scalar.AspNetCore;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Serilog
builder.Host.UseSerilog((context, configuration) =>
    configuration.ReadFrom.Configuration(context.Configuration));

// Layer registrations
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddJwtAuthentication(builder.Configuration);
builder.Services.AddAuthorizationPolicies();

// Controllers with validation filter
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationFilter>();
})
.AddJsonOptions(options =>
{
    // Serialize enums as their string name (e.g. "Motor", "Active") rather than
    // the underlying int. Matches how enums are stored in the DB via
    // .HasConversion<string>() and keeps the API contract human-readable.
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

// OpenAPI with JWT Bearer auth
builder.Services.AddOpenApiWithAuth();

// Read origins from appsettings.json
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? Array.Empty<string>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("ReactCorsPolicy", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials()
            .WithExposedHeaders("Content-Disposition", "X-Total-Count"); // Expose any custom headers
    });
});


var app = builder.Build();

// Middleware pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(options =>
    {
        options.WithTitle("ClaimAI API");
        options.WithDefaultHttpClient(ScalarTarget.CSharp, ScalarClient.HttpClient);
    });
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<RequestLoggingMiddleware>();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles(); // serve wwwroot (profile photos, etc.)

app.UseRouting();

// CORS must come after UseRouting and before UseAuthentication/UseAuthorization
app.UseCors("ReactCorsPolicy");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

await RoleSeeder.SeedAsync(app.Services);

app.Run();
