using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ClaimAI.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddAppVersion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AppVersions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Platform = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    VersionName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    VersionCode = table.Column<int>(type: "integer", nullable: false),
                    MinSupportedVersionCode = table.Column<int>(type: "integer", nullable: false),
                    IsLatest = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    IsMandatory = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ReleaseNotes = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: true),
                    ReleaseDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    StoreUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppVersions", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AppVersions_Platform_IsLatest",
                table: "AppVersions",
                column: "Platform",
                unique: true,
                filter: "\"IsDeleted\" = false AND \"IsLatest\" = true");

            migrationBuilder.CreateIndex(
                name: "IX_AppVersions_Platform_VersionCode",
                table: "AppVersions",
                columns: new[] { "Platform", "VersionCode" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            // UserDevices table + indexes already exist in the database from an
            // earlier change that was not captured as a migration. The model
            // snapshot now tracks them, so future diffs are consistent — but we
            // skip recreating them here to avoid 42P07 ("relation already exists").
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AppVersions");
        }
    }
}
