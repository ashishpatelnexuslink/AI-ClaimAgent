using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class DropCategoryAddGroupKeyAndLabelToClaimDocument : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add the new columns first so we can backfill them from Category
            // before dropping it.
            migrationBuilder.AddColumn<string>(
                name: "GroupKey",
                table: "ClaimDocuments",
                type: "character varying(60)",
                maxLength: 60,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Label",
                table: "ClaimDocuments",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true);

            // Backfill GroupKey from the legacy Category strings so existing
            // ClaimDocument rows still match the new template GroupKeys after
            // Category is gone. Label is left null for legacy rows; new uploads
            // populate it from the active template at upload time.
            migrationBuilder.Sql(@"
                UPDATE ""ClaimDocuments""
                SET ""GroupKey"" = CASE ""Category""
                    WHEN 'VehiclePhoto'       THEN 'vehicle_photos'
                    WHEN 'DamagePhoto'        THEN 'damage_photos'
                    WHEN 'DriverLicense'      THEN 'driver_license'
                    WHEN 'BillInvoice'        THEN 'bill_invoice'
                    WHEN 'PoliceReport'       THEN 'police_report'
                    WHEN 'SupportingDocument' THEN 'supporting_docs'
                    ELSE ""Category""
                END
                WHERE ""Category"" IS NOT NULL;
            ");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "ClaimDocuments");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "GroupKey",
                table: "ClaimDocuments");

            migrationBuilder.DropColumn(
                name: "Label",
                table: "ClaimDocuments");

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "ClaimDocuments",
                type: "character varying(40)",
                maxLength: 40,
                nullable: true);
        }
    }
}
