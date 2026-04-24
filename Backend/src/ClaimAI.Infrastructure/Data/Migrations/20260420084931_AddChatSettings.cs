using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddChatSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ChatThreadId",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ClaimantType",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CoverageType",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FullName",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "IncidentDate",
                table: "Claims",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IncidentDescription",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "IncidentLocation",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PolicyStatus",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PolicyValidUntil",
                table: "Claims",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "VehicleModel",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "VehicleNumber",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "VehicleRegistrationNumber",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "VinNumber",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ChatSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    RequireClaimantType = table.Column<bool>(type: "boolean", nullable: false),
                    MinIdentifiersRequired = table.Column<int>(type: "integer", nullable: false),
                    MinPhotos = table.Column<int>(type: "integer", nullable: false),
                    MaxPhotos = table.Column<int>(type: "integer", nullable: false),
                    PhotoAllowedExtensions = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    PhotoImageQuality = table.Column<int>(type: "integer", nullable: false),
                    MaxPhotoSizeMB = table.Column<int>(type: "integer", nullable: false),
                    DocumentAllowedExtensions = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    MaxDocumentSizeMB = table.Column<int>(type: "integer", nullable: false),
                    RequireIncidentDescription = table.Column<bool>(type: "boolean", nullable: false),
                    MinDescriptionLength = table.Column<int>(type: "integer", nullable: false),
                    MaxDescriptionLength = table.Column<int>(type: "integer", nullable: false),
                    RequireLocation = table.Column<bool>(type: "boolean", nullable: false),
                    AllowCurrentLocation = table.Column<bool>(type: "boolean", nullable: false),
                    RequireIncidentDateTime = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatSettings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ChatSettingItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ChatSettingId = table.Column<Guid>(type: "uuid", nullable: false),
                    ItemType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    ItemKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    MinCount = table.Column<int>(type: "integer", nullable: false),
                    MaxCount = table.Column<int>(type: "integer", nullable: false),
                    IsRequired = table.Column<bool>(type: "boolean", nullable: false),
                    AllowSkip = table.Column<bool>(type: "boolean", nullable: false),
                    AllowedFileExtensions = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatSettingItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChatSettingItems_ChatSettings_ChatSettingId",
                        column: x => x.ChatSettingId,
                        principalTable: "ChatSettings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "ChatSettings",
                columns: new[] { "Id", "AllowCurrentLocation", "CreatedAt", "CreatedBy", "DocumentAllowedExtensions", "IsActive", "IsDeleted", "MaxDescriptionLength", "MaxDocumentSizeMB", "MaxPhotoSizeMB", "MaxPhotos", "MinDescriptionLength", "MinIdentifiersRequired", "MinPhotos", "Name", "PhotoAllowedExtensions", "PhotoImageQuality", "RequireClaimantType", "RequireIncidentDateTime", "RequireIncidentDescription", "RequireLocation", "UpdatedAt", "UpdatedBy" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), true, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, "pdf,jpg,jpeg,png,doc,docx", true, false, 2000, 25, 10, 4, 20, 2, 4, "Default", "jpg,jpeg,png", 80, true, true, true, true, null, null });

            migrationBuilder.InsertData(
                table: "ChatSettingItems",
                columns: new[] { "Id", "AllowSkip", "AllowedFileExtensions", "ChatSettingId", "CreatedAt", "CreatedBy", "IsActive", "IsDeleted", "IsRequired", "ItemKey", "ItemType", "MaxCount", "MinCount", "SortOrder", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("22222222-0000-0000-0000-000000000001"), true, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, false, "vehicle_registration", "Identifier", 1, 1, 1, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000002"), true, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, false, "policy_number", "Identifier", 1, 1, 2, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000003"), true, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, false, "vin", "Identifier", 1, 1, 3, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000004"), false, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, true, "damage_photo", "Photo", 4, 4, 4, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000005"), false, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, true, "driving_license_front", "DrivingLicense", 1, 1, 5, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000006"), false, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, true, "driving_license_back", "DrivingLicense", 1, 1, 6, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000007"), false, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, true, "insurance_policy", "Document", 1, 1, 7, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000008"), false, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, true, "police_report", "Document", 1, 1, 8, null, null },
                    { new Guid("22222222-0000-0000-0000-000000000009"), true, null, new Guid("11111111-1111-1111-1111-111111111111"), new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, true, false, false, "bill_invoice", "Invoice", 1, 0, 9, null, null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChatSettingItems_ChatSettingId",
                table: "ChatSettingItems",
                column: "ChatSettingId");

            migrationBuilder.CreateIndex(
                name: "IX_ChatSettingItems_ChatSettingId_ItemKey",
                table: "ChatSettingItems",
                columns: new[] { "ChatSettingId", "ItemKey" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_ChatSettings_IsActive",
                table: "ChatSettings",
                column: "IsActive",
                unique: true,
                filter: "\"IsActive\" = true");

            migrationBuilder.CreateIndex(
                name: "IX_ChatSettings_Name",
                table: "ChatSettings",
                column: "Name",
                unique: true,
                filter: "\"IsDeleted\" = false");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChatSettingItems");

            migrationBuilder.DropTable(
                name: "ChatSettings");

            migrationBuilder.DropColumn(
                name: "ChatThreadId",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "ClaimantType",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "CoverageType",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "FullName",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "IncidentDate",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "IncidentDescription",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "IncidentLocation",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "PolicyStatus",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "PolicyValidUntil",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VehicleModel",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VehicleNumber",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VehicleRegistrationNumber",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VinNumber",
                table: "Claims");
        }
    }
}
