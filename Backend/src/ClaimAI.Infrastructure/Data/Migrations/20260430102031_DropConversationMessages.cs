using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class DropConversationMessages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ConversationMessages");

            migrationBuilder.DropColumn(
                name: "Title",
                table: "Conversations");

            migrationBuilder.AddColumn<string>(
                name: "JsonFilePath",
                table: "Conversations",
                type: "character varying(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ThreadId",
                table: "Conversations",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_Conversations_ThreadId",
                table: "Conversations",
                column: "ThreadId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Conversations_ThreadId",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "JsonFilePath",
                table: "Conversations");

            migrationBuilder.DropColumn(
                name: "ThreadId",
                table: "Conversations");

            migrationBuilder.AddColumn<string>(
                name: "Title",
                table: "Conversations",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ConversationMessages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ConversationId = table.Column<Guid>(type: "uuid", nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    Metadata = table.Column<string>(type: "jsonb", nullable: true),
                    Role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ConversationMessages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ConversationMessages_Conversations_ConversationId",
                        column: x => x.ConversationId,
                        principalTable: "Conversations",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ConversationMessages_ConversationId_CreatedAt",
                table: "ConversationMessages",
                columns: new[] { "ConversationId", "CreatedAt" });
        }
    }
}
