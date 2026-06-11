using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationTemplates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "TemplateKey",
                table: "Notifications",
                type: "character varying(80)",
                maxLength: 80,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TemplateParams",
                table: "Notifications",
                type: "jsonb",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "NotificationTemplates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Key = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    DefaultTitle = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    DefaultMessage = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationTemplates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "NotificationTemplateTranslations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    NotificationTemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    Locale = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_NotificationTemplateTranslations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_NotificationTemplateTranslations_NotificationTemplates_Noti~",
                        column: x => x.NotificationTemplateId,
                        principalTable: "NotificationTemplates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "NotificationTemplates",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "DefaultMessage", "DefaultTitle", "IsDeleted", "Key", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("55555555-0001-0000-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, "Your claim is now under review.{noteSuffix}", "Claim {claimNumber} updated", false, "claim.status.inReview", null, null },
                    { new Guid("55555555-0002-0000-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, "Your claim has been approved.{noteSuffix}", "Claim {claimNumber} updated", false, "claim.status.approved", null, null },
                    { new Guid("55555555-0003-0000-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, "Your claim has been rejected.{noteSuffix}", "Claim {claimNumber} updated", false, "claim.status.rejected", null, null },
                    { new Guid("55555555-0004-0000-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, "Please upload photos and supporting documents to complete your claim {claimNumber}.", "Action Required", false, "claim.action.uploadPhotosAndDocs", null, null },
                    { new Guid("55555555-0005-0000-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, "Please upload photos of the damage to complete your claim {claimNumber}.", "Action Required", false, "claim.action.uploadPhotos", null, null },
                    { new Guid("55555555-0006-0000-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, "Please upload supporting documents to complete your claim {claimNumber}.", "Action Required", false, "claim.action.uploadDocs", null, null }
                });

            migrationBuilder.InsertData(
                table: "NotificationTemplateTranslations",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "IsDeleted", "Locale", "Message", "NotificationTemplateId", "Title", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("55555555-0001-0001-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "de", "Ihr Schaden wird jetzt geprüft.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Schaden {claimNumber} aktualisiert", null, null },
                    { new Guid("55555555-0001-0002-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "es", "Su siniestro está ahora en revisión.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Siniestro {claimNumber} actualizado", null, null },
                    { new Guid("55555555-0001-0003-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "fr", "Votre sinistre est désormais en cours d'examen.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Sinistre {claimNumber} mis à jour", null, null },
                    { new Guid("55555555-0001-0004-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "it", "Il tuo sinistro è ora in revisione.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Sinistro {claimNumber} aggiornato", null, null },
                    { new Guid("55555555-0001-0005-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lt", "Jūsų žala dabar peržiūrima.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Žala {claimNumber} atnaujinta", null, null },
                    { new Guid("55555555-0001-0006-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lv", "Jūsu prasība pašlaik tiek izskatīta.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Prasība {claimNumber} atjaunināta", null, null },
                    { new Guid("55555555-0001-0007-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "pl", "Twoje roszczenie jest teraz weryfikowane.{noteSuffix}", new Guid("55555555-0001-0000-0000-000000000000"), "Roszczenie {claimNumber} zaktualizowane", null, null },
                    { new Guid("55555555-0002-0001-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "de", "Ihr Schaden wurde genehmigt.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Schaden {claimNumber} aktualisiert", null, null },
                    { new Guid("55555555-0002-0002-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "es", "Su siniestro ha sido aprobado.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Siniestro {claimNumber} actualizado", null, null },
                    { new Guid("55555555-0002-0003-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "fr", "Votre sinistre a été approuvé.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Sinistre {claimNumber} mis à jour", null, null },
                    { new Guid("55555555-0002-0004-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "it", "Il tuo sinistro è stato approvato.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Sinistro {claimNumber} aggiornato", null, null },
                    { new Guid("55555555-0002-0005-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lt", "Jūsų žala patvirtinta.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Žala {claimNumber} atnaujinta", null, null },
                    { new Guid("55555555-0002-0006-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lv", "Jūsu prasība ir apstiprināta.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Prasība {claimNumber} atjaunināta", null, null },
                    { new Guid("55555555-0002-0007-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "pl", "Twoje roszczenie zostało zatwierdzone.{noteSuffix}", new Guid("55555555-0002-0000-0000-000000000000"), "Roszczenie {claimNumber} zaktualizowane", null, null },
                    { new Guid("55555555-0003-0001-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "de", "Ihr Schaden wurde abgelehnt.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Schaden {claimNumber} aktualisiert", null, null },
                    { new Guid("55555555-0003-0002-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "es", "Su siniestro ha sido rechazado.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Siniestro {claimNumber} actualizado", null, null },
                    { new Guid("55555555-0003-0003-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "fr", "Votre sinistre a été rejeté.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Sinistre {claimNumber} mis à jour", null, null },
                    { new Guid("55555555-0003-0004-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "it", "Il tuo sinistro è stato rifiutato.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Sinistro {claimNumber} aggiornato", null, null },
                    { new Guid("55555555-0003-0005-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lt", "Jūsų žala atmesta.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Žala {claimNumber} atnaujinta", null, null },
                    { new Guid("55555555-0003-0006-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lv", "Jūsu prasība ir noraidīta.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Prasība {claimNumber} atjaunināta", null, null },
                    { new Guid("55555555-0003-0007-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "pl", "Twoje roszczenie zostało odrzucone.{noteSuffix}", new Guid("55555555-0003-0000-0000-000000000000"), "Roszczenie {claimNumber} zaktualizowane", null, null },
                    { new Guid("55555555-0004-0001-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "de", "Bitte laden Sie Fotos und Belege hoch, um Ihren Schaden {claimNumber} abzuschließen.", new Guid("55555555-0004-0000-0000-000000000000"), "Aktion erforderlich", null, null },
                    { new Guid("55555555-0004-0002-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "es", "Sube fotos y documentos de respaldo para completar tu siniestro {claimNumber}.", new Guid("55555555-0004-0000-0000-000000000000"), "Acción requerida", null, null },
                    { new Guid("55555555-0004-0003-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "fr", "Veuillez téléverser des photos et des justificatifs pour compléter votre sinistre {claimNumber}.", new Guid("55555555-0004-0000-0000-000000000000"), "Action requise", null, null },
                    { new Guid("55555555-0004-0004-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "it", "Carica foto e documenti di supporto per completare il tuo sinistro {claimNumber}.", new Guid("55555555-0004-0000-0000-000000000000"), "Azione richiesta", null, null },
                    { new Guid("55555555-0004-0005-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lt", "Įkelkite nuotraukas ir patvirtinamuosius dokumentus, kad užbaigtumėte žalą {claimNumber}.", new Guid("55555555-0004-0000-0000-000000000000"), "Reikalingas veiksmas", null, null },
                    { new Guid("55555555-0004-0006-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lv", "Lūdzu, augšupielādējiet fotogrāfijas un pamatojuma dokumentus, lai pabeigtu prasību {claimNumber}.", new Guid("55555555-0004-0000-0000-000000000000"), "Nepieciešama darbība", null, null },
                    { new Guid("55555555-0004-0007-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "pl", "Prześlij zdjęcia i dokumenty potwierdzające, aby ukończyć roszczenie {claimNumber}.", new Guid("55555555-0004-0000-0000-000000000000"), "Wymagane działanie", null, null },
                    { new Guid("55555555-0005-0001-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "de", "Bitte laden Sie Fotos des Schadens hoch, um Ihren Schaden {claimNumber} abzuschließen.", new Guid("55555555-0005-0000-0000-000000000000"), "Aktion erforderlich", null, null },
                    { new Guid("55555555-0005-0002-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "es", "Sube fotos del daño para completar tu siniestro {claimNumber}.", new Guid("55555555-0005-0000-0000-000000000000"), "Acción requerida", null, null },
                    { new Guid("55555555-0005-0003-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "fr", "Veuillez téléverser des photos des dommages pour compléter votre sinistre {claimNumber}.", new Guid("55555555-0005-0000-0000-000000000000"), "Action requise", null, null },
                    { new Guid("55555555-0005-0004-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "it", "Carica foto del danno per completare il tuo sinistro {claimNumber}.", new Guid("55555555-0005-0000-0000-000000000000"), "Azione richiesta", null, null },
                    { new Guid("55555555-0005-0005-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lt", "Įkelkite žalos nuotraukas, kad užbaigtumėte žalą {claimNumber}.", new Guid("55555555-0005-0000-0000-000000000000"), "Reikalingas veiksmas", null, null },
                    { new Guid("55555555-0005-0006-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lv", "Lūdzu, augšupielādējiet bojājumu fotogrāfijas, lai pabeigtu prasību {claimNumber}.", new Guid("55555555-0005-0000-0000-000000000000"), "Nepieciešama darbība", null, null },
                    { new Guid("55555555-0005-0007-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "pl", "Prześlij zdjęcia uszkodzeń, aby ukończyć roszczenie {claimNumber}.", new Guid("55555555-0005-0000-0000-000000000000"), "Wymagane działanie", null, null },
                    { new Guid("55555555-0006-0001-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "de", "Bitte laden Sie Belege hoch, um Ihren Schaden {claimNumber} abzuschließen.", new Guid("55555555-0006-0000-0000-000000000000"), "Aktion erforderlich", null, null },
                    { new Guid("55555555-0006-0002-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "es", "Sube documentos de respaldo para completar tu siniestro {claimNumber}.", new Guid("55555555-0006-0000-0000-000000000000"), "Acción requerida", null, null },
                    { new Guid("55555555-0006-0003-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "fr", "Veuillez téléverser des justificatifs pour compléter votre sinistre {claimNumber}.", new Guid("55555555-0006-0000-0000-000000000000"), "Action requise", null, null },
                    { new Guid("55555555-0006-0004-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "it", "Carica documenti di supporto per completare il tuo sinistro {claimNumber}.", new Guid("55555555-0006-0000-0000-000000000000"), "Azione richiesta", null, null },
                    { new Guid("55555555-0006-0005-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lt", "Įkelkite patvirtinamuosius dokumentus, kad užbaigtumėte žalą {claimNumber}.", new Guid("55555555-0006-0000-0000-000000000000"), "Reikalingas veiksmas", null, null },
                    { new Guid("55555555-0006-0006-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "lv", "Lūdzu, augšupielādējiet pamatojuma dokumentus, lai pabeigtu prasību {claimNumber}.", new Guid("55555555-0006-0000-0000-000000000000"), "Nepieciešama darbība", null, null },
                    { new Guid("55555555-0006-0007-0000-000000000000"), new DateTime(2026, 6, 11, 0, 0, 0, 0, DateTimeKind.Utc), null, false, "pl", "Prześlij dokumenty potwierdzające, aby ukończyć roszczenie {claimNumber}.", new Guid("55555555-0006-0000-0000-000000000000"), "Wymagane działanie", null, null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_NotificationTemplates_Key",
                table: "NotificationTemplates",
                column: "Key",
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_NotificationTemplateTranslations_NotificationTemplateId_Loc~",
                table: "NotificationTemplateTranslations",
                columns: new[] { "NotificationTemplateId", "Locale" },
                unique: true,
                filter: "\"IsDeleted\" = false");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "NotificationTemplateTranslations");

            migrationBuilder.DropTable(
                name: "NotificationTemplates");

            migrationBuilder.DropColumn(
                name: "TemplateKey",
                table: "Notifications");

            migrationBuilder.DropColumn(
                name: "TemplateParams",
                table: "Notifications");
        }
    }
}
