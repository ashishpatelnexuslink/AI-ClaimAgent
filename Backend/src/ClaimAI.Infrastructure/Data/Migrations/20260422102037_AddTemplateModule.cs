using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTemplateModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Templates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    InsuranceType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "Draft"),
                    ClaimantTypes = table.Column<string>(type: "jsonb", nullable: false),
                    RequireIncidentDt = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    RequireLocation = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    MinDescriptionLen = table.Column<int>(type: "integer", nullable: false, defaultValue: 40),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Templates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TemplateDocumentSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    DocKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Label = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Instruction = table.Column<string>(type: "text", nullable: true),
                    MinCount = table.Column<int>(type: "integer", nullable: false),
                    MaxCount = table.Column<int>(type: "integer", nullable: false),
                    IsRequired = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    MaxFileSizeMb = table.Column<int>(type: "integer", nullable: false, defaultValue: 10),
                    AllowedMimeTypes = table.Column<string>(type: "jsonb", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateDocumentSettings", x => x.Id);
                    table.CheckConstraint("CK_TemplateDocumentSettings_CountRange", "\"MinCount\" >= 0 AND \"MaxCount\" >= \"MinCount\"");
                    table.CheckConstraint("CK_TemplateDocumentSettings_FileSize", "\"MaxFileSizeMb\" BETWEEN 1 AND 100");
                    table.ForeignKey(
                        name: "FK_TemplateDocumentSettings_Templates_TemplateId",
                        column: x => x.TemplateId,
                        principalTable: "Templates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TemplateFieldGroupRules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    MinRequired = table.Column<int>(type: "integer", nullable: false),
                    MaxAllowed = table.Column<int>(type: "integer", nullable: true),
                    ErrorMessage = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateFieldGroupRules", x => x.Id);
                    table.CheckConstraint("CK_TemplateFieldGroupRules_MaxGteMin", "\"MaxAllowed\" IS NULL OR \"MaxAllowed\" >= \"MinRequired\"");
                    table.CheckConstraint("CK_TemplateFieldGroupRules_MinNonNegative", "\"MinRequired\" >= 0");
                    table.ForeignKey(
                        name: "FK_TemplateFieldGroupRules_Templates_TemplateId",
                        column: x => x.TemplateId,
                        principalTable: "Templates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TemplateIdentityFields",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    FieldKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Label = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    PromptText = table.Column<string>(type: "text", nullable: false),
                    Placeholder = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: true),
                    ValidationRegex = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    GroupKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: true),
                    IsSkippable = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateIdentityFields", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TemplateIdentityFields_Templates_TemplateId",
                        column: x => x.TemplateId,
                        principalTable: "Templates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TemplatePhotoSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    GroupKey = table.Column<string>(type: "character varying(60)", maxLength: 60, nullable: false),
                    Label = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Instruction = table.Column<string>(type: "text", nullable: true),
                    MinCount = table.Column<int>(type: "integer", nullable: false),
                    MaxCount = table.Column<int>(type: "integer", nullable: false),
                    IsRequired = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    AllowedAngles = table.Column<string>(type: "jsonb", nullable: false),
                    SampleImageUrls = table.Column<string>(type: "jsonb", nullable: false),
                    MaxFileSizeMb = table.Column<int>(type: "integer", nullable: false, defaultValue: 10),
                    AllowedMimeTypes = table.Column<string>(type: "jsonb", nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplatePhotoSettings", x => x.Id);
                    table.CheckConstraint("CK_TemplatePhotoSettings_CountRange", "\"MinCount\" >= 0 AND \"MaxCount\" >= \"MinCount\"");
                    table.CheckConstraint("CK_TemplatePhotoSettings_FileSize", "\"MaxFileSizeMb\" BETWEEN 1 AND 100");
                    table.ForeignKey(
                        name: "FK_TemplatePhotoSettings_Templates_TemplateId",
                        column: x => x.TemplateId,
                        principalTable: "Templates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Templates",
                columns: new[] { "Id", "ClaimantTypes", "CompanyName", "CreatedAt", "CreatedBy", "InsuranceType", "IsDeleted", "MinDescriptionLen", "Name", "RequireIncidentDt", "RequireLocation", "Status", "UpdatedAt", "UpdatedBy", "Version" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), "[\"PolicyHolder\",\"ThirdParty\"]", "Draudita Insurance", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Motor", false, 40, "Draudita Motor Comprehensive", true, true, "Active", null, null, 1 });

            migrationBuilder.InsertData(
                table: "TemplateDocumentSettings",
                columns: new[] { "Id", "AllowedMimeTypes", "CreatedAt", "CreatedBy", "DisplayOrder", "DocKey", "Instruction", "IsDeleted", "Label", "MaxCount", "MaxFileSizeMb", "MinCount", "TemplateId", "UpdatedAt", "UpdatedBy" },
                values: new object[] { new Guid("55555555-0001-0000-0000-000000000000"), "[\"application/pdf\",\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 1, "bill_invoice", "Upload the repair bill or invoice.", false, "Bill / Invoice", 2, 10, 1, new Guid("11111111-1111-1111-1111-111111111111"), null, null });

            migrationBuilder.InsertData(
                table: "TemplateDocumentSettings",
                columns: new[] { "Id", "AllowedMimeTypes", "CreatedAt", "CreatedBy", "DisplayOrder", "DocKey", "Instruction", "IsDeleted", "IsRequired", "Label", "MaxCount", "MaxFileSizeMb", "MinCount", "TemplateId", "UpdatedAt", "UpdatedBy" },
                values: new object[] { new Guid("55555555-0002-0000-0000-000000000000"), "[\"application/pdf\",\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 2, "insurance_policy", "Upload the current insurance policy document.", false, true, "Insurance Policy", 1, 10, 1, new Guid("11111111-1111-1111-1111-111111111111"), null, null });

            migrationBuilder.InsertData(
                table: "TemplateDocumentSettings",
                columns: new[] { "Id", "AllowedMimeTypes", "CreatedAt", "CreatedBy", "DisplayOrder", "DocKey", "Instruction", "IsDeleted", "Label", "MaxCount", "MaxFileSizeMb", "MinCount", "TemplateId", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("55555555-0003-0000-0000-000000000000"), "[\"application/pdf\",\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 3, "police_report", "If available, upload the police report.", false, "Police Report", 1, 10, 0, new Guid("11111111-1111-1111-1111-111111111111"), null, null },
                    { new Guid("55555555-0004-0000-0000-000000000000"), "[\"application/pdf\",\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 4, "supporting_docs", "Upload any additional supporting documents.", false, "Supporting Documents", 10, 10, 0, new Guid("11111111-1111-1111-1111-111111111111"), null, null }
                });

            migrationBuilder.InsertData(
                table: "TemplateFieldGroupRules",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "ErrorMessage", "GroupKey", "IsDeleted", "MaxAllowed", "MinRequired", "TemplateId", "UpdatedAt", "UpdatedBy" },
                values: new object[] { new Guid("33333333-0001-0000-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "A minimum of two inputs is required. Kindly provide any of the following: Vehicle Registration Number, Vehicle Identification Number, or Vehicle Number.", "vehicle_identity", false, 3, 2, new Guid("11111111-1111-1111-1111-111111111111"), null, null });

            migrationBuilder.InsertData(
                table: "TemplateIdentityFields",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "DisplayOrder", "FieldKey", "GroupKey", "IsDeleted", "Label", "Placeholder", "PromptText", "TemplateId", "UpdatedAt", "UpdatedBy", "ValidationRegex" },
                values: new object[] { new Guid("22222222-0001-0000-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 1, "full_name", null, false, "Full Name", null, "Kindly provide your full name as per official records.", new Guid("11111111-1111-1111-1111-111111111111"), null, null, null });

            migrationBuilder.InsertData(
                table: "TemplateIdentityFields",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "DisplayOrder", "FieldKey", "GroupKey", "IsDeleted", "IsSkippable", "Label", "Placeholder", "PromptText", "TemplateId", "UpdatedAt", "UpdatedBy", "ValidationRegex" },
                values: new object[,]
                {
                    { new Guid("22222222-0002-0000-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 2, "vehicle_reg", "vehicle_identity", false, true, "Vehicle Registration No.", null, "Please provide your vehicle registration number.", new Guid("11111111-1111-1111-1111-111111111111"), null, null, null },
                    { new Guid("22222222-0003-0000-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 3, "policy_number", "vehicle_identity", false, true, "Policy Number", null, "Please provide your insurance policy number for verification.", new Guid("11111111-1111-1111-1111-111111111111"), null, null, null },
                    { new Guid("22222222-0004-0000-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 4, "vin", "vehicle_identity", false, true, "VIN Number", null, "Please provide the Vehicle Identification Number (VIN).", new Guid("11111111-1111-1111-1111-111111111111"), null, null, null }
                });

            migrationBuilder.InsertData(
                table: "TemplatePhotoSettings",
                columns: new[] { "Id", "AllowedAngles", "AllowedMimeTypes", "CreatedAt", "CreatedBy", "DisplayOrder", "GroupKey", "Instruction", "IsDeleted", "IsRequired", "Label", "MaxCount", "MaxFileSizeMb", "MinCount", "SampleImageUrls", "TemplateId", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("44444444-0001-0000-0000-000000000000"), "[\"front_left\",\"front_right\",\"rear_left\",\"rear_right\"]", "[\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 1, "vehicle_photos", "Please upload four photos of the vehicle from each corner.", false, true, "Vehicle Photos", 4, 10, 4, "[]", new Guid("11111111-1111-1111-1111-111111111111"), null, null },
                    { new Guid("44444444-0002-0000-0000-000000000000"), "[\"front\",\"side\",\"close_up\"]", "[\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 2, "damage_photos", "Upload clear photos of the damage from multiple angles.", false, true, "Damage Photos", 10, 10, 2, "[]", new Guid("11111111-1111-1111-1111-111111111111"), null, null },
                    { new Guid("44444444-0003-0000-0000-000000000000"), "[\"front\",\"back\"]", "[\"image/jpeg\",\"image/png\"]", new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, 3, "driver_license", "Upload the front and back of the driver license.", false, true, "Driver License", 2, 10, 1, "[]", new Guid("11111111-1111-1111-1111-111111111111"), null, null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_TemplateDocumentSettings_TemplateId_DocKey",
                table: "TemplateDocumentSettings",
                columns: new[] { "TemplateId", "DocKey" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_TemplateFieldGroupRules_TemplateId_GroupKey",
                table: "TemplateFieldGroupRules",
                columns: new[] { "TemplateId", "GroupKey" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_TemplateIdentityFields_TemplateId_DisplayOrder",
                table: "TemplateIdentityFields",
                columns: new[] { "TemplateId", "DisplayOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_TemplateIdentityFields_TemplateId_FieldKey",
                table: "TemplateIdentityFields",
                columns: new[] { "TemplateId", "FieldKey" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_TemplatePhotoSettings_TemplateId_GroupKey",
                table: "TemplatePhotoSettings",
                columns: new[] { "TemplateId", "GroupKey" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_Templates_Active_Singleton",
                table: "Templates",
                columns: new[] { "CompanyName", "InsuranceType" },
                unique: true,
                filter: "\"Status\" = 'Active' AND \"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_Templates_CompanyName_InsuranceType_Version",
                table: "Templates",
                columns: new[] { "CompanyName", "InsuranceType", "Version" },
                unique: true,
                filter: "\"IsDeleted\" = false");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TemplateDocumentSettings");

            migrationBuilder.DropTable(
                name: "TemplateFieldGroupRules");

            migrationBuilder.DropTable(
                name: "TemplateIdentityFields");

            migrationBuilder.DropTable(
                name: "TemplatePhotoSettings");

            migrationBuilder.DropTable(
                name: "Templates");
        }
    }
}
