using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddClaimSummaryFieldsAndDocumentCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DamagePhotosCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "IdentityVerified",
                table: "Claims",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LicensePhotosCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "PoliceReportCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RepairBillCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "VehiclePhotosCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "ClaimDocuments",
                type: "character varying(40)",
                maxLength: 40,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DamagePhotosCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "IdentityVerified",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "LicensePhotosCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "PoliceReportCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "RepairBillCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VehiclePhotosCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "ClaimDocuments");
        }
    }
}
