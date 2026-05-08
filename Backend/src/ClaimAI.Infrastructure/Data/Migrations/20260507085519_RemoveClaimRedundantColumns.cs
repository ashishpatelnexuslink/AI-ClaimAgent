using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class RemoveClaimRedundantColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AdditionalData",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "AssignedTo",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "CoverageType",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "DamagePhotosCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "LicensePhotosCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "PatientName",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "PoliceReportCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "RepairBillCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "SupportingDocsCount",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VehicleNumber",
                table: "Claims");

            migrationBuilder.DropColumn(
                name: "VehiclePhotosCount",
                table: "Claims");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AdditionalData",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AssignedTo",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CoverageType",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "DamagePhotosCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LicensePhotosCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "PatientName",
                table: "Claims",
                type: "text",
                nullable: true);

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
                name: "SupportingDocsCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "VehicleNumber",
                table: "Claims",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "VehiclePhotosCount",
                table: "Claims",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }
    }
}
