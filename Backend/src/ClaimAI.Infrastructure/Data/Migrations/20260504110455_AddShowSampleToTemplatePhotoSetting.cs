using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddShowSampleToTemplatePhotoSetting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "ShowSample",
                table: "TemplatePhotoSettings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.UpdateData(
                table: "TemplatePhotoSettings",
                keyColumn: "Id",
                keyValue: new Guid("44444444-0001-0000-0000-000000000000"),
                column: "ShowSample",
                value: true);

            migrationBuilder.UpdateData(
                table: "TemplatePhotoSettings",
                keyColumn: "Id",
                keyValue: new Guid("44444444-0002-0000-0000-000000000000"),
                column: "ShowSample",
                value: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ShowSample",
                table: "TemplatePhotoSettings");
        }
    }
}
