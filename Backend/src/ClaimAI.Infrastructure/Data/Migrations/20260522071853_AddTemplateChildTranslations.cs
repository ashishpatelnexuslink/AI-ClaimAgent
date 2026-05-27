using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace ClaimAI.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddTemplateChildTranslations : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "TemplateDocumentSettingTranslations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateDocumentSettingId = table.Column<Guid>(type: "uuid", nullable: false),
                    Locale = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Label = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Instruction = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateDocumentSettingTranslations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TemplateDocumentSettingTranslations_TemplateDocumentSetting~",
                        column: x => x.TemplateDocumentSettingId,
                        principalTable: "TemplateDocumentSettings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TemplateIdentityFieldTranslations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateIdentityFieldId = table.Column<Guid>(type: "uuid", nullable: false),
                    Locale = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Label = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    PromptText = table.Column<string>(type: "text", nullable: false),
                    Placeholder = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplateIdentityFieldTranslations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TemplateIdentityFieldTranslations_TemplateIdentityFields_Te~",
                        column: x => x.TemplateIdentityFieldId,
                        principalTable: "TemplateIdentityFields",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "TemplatePhotoSettingTranslations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplatePhotoSettingId = table.Column<Guid>(type: "uuid", nullable: false),
                    Locale = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Label = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Instruction = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedBy = table.Column<string>(type: "text", nullable: true),
                    UpdatedBy = table.Column<string>(type: "text", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TemplatePhotoSettingTranslations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TemplatePhotoSettingTranslations_TemplatePhotoSettings_Temp~",
                        column: x => x.TemplatePhotoSettingId,
                        principalTable: "TemplatePhotoSettings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "TemplateDocumentSettingTranslations",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "Instruction", "IsDeleted", "Label", "Locale", "TemplateDocumentSettingId", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("55555555-0001-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Laden Sie die Reparaturrechnung oder den Beleg hoch.", false, "Rechnung / Beleg", "de", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0001-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Carica la fattura della riparazione o la ricevuta.", false, "Fattura / Ricevuta", "it", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0001-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Téléversez la facture ou le reçu de la réparation.", false, "Facture / Reçu", "fr", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0001-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Sube la factura o el recibo de la reparación.", false, "Factura / Recibo", "es", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0001-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Prześlij rachunek lub fakturę za naprawę.", false, "Rachunek / Faktura", "pl", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0001-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Įkelkite remonto sąskaitą arba kvitą.", false, "Sąskaita / Kvitas", "lt", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0001-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Augšupielādējiet remonta rēķinu vai kvīti.", false, "Rēķins / Kvīts", "lv", new Guid("55555555-0001-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Laden Sie das aktuelle Versicherungsdokument hoch.", false, "Versicherungspolice", "de", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Carica il documento attuale della polizza assicurativa.", false, "Polizza assicurativa", "it", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Téléversez le document de police d'assurance en cours.", false, "Police d'assurance", "fr", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Sube el documento de la póliza de seguro vigente.", false, "Póliza de seguro", "es", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Prześlij aktualny dokument polisy ubezpieczeniowej.", false, "Polisa ubezpieczeniowa", "pl", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Įkelkite galiojantį draudimo poliso dokumentą.", false, "Draudimo polisas", "lt", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0002-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Augšupielādējiet pašreizējo apdrošināšanas polises dokumentu.", false, "Apdrošināšanas polise", "lv", new Guid("55555555-0002-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Falls vorhanden, laden Sie den Polizeibericht hoch.", false, "Polizeibericht", "de", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Se disponibile, carica il rapporto della polizia.", false, "Rapporto di polizia", "it", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Si disponible, téléversez le rapport de police.", false, "Rapport de police", "fr", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Si está disponible, sube el informe policial.", false, "Informe policial", "es", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Jeśli jest dostępny, prześlij raport policyjny.", false, "Raport policyjny", "pl", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Jei turite, įkelkite policijos ataskaitą.", false, "Policijos ataskaita", "lt", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0003-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Ja pieejams, augšupielādējiet policijas ziņojumu.", false, "Policijas ziņojums", "lv", new Guid("55555555-0003-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Laden Sie weitere unterstützende Dokumente hoch.", false, "Belege", "de", new Guid("55555555-0004-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Carica eventuali altri documenti di supporto.", false, "Documenti di supporto", "it", new Guid("55555555-0004-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Téléversez tout document justificatif supplémentaire.", false, "Documents justificatifs", "fr", new Guid("55555555-0004-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Sube cualquier documento de apoyo adicional.", false, "Documentos de apoyo", "es", new Guid("55555555-0004-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Prześlij wszelkie dodatkowe dokumenty uzupełniające.", false, "Dokumenty uzupełniające", "pl", new Guid("55555555-0004-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Įkelkite bet kokius papildomus pagrindžiančius dokumentus.", false, "Papildomi dokumentai", "lt", new Guid("55555555-0004-0000-0000-000000000000"), null, null },
                    { new Guid("55555555-0004-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Augšupielādējiet jebkurus papildu pavaddokumentus.", false, "Pavaddokumenti", "lv", new Guid("55555555-0004-0000-0000-000000000000"), null, null }
                });

            migrationBuilder.InsertData(
                table: "TemplatePhotoSettingTranslations",
                columns: new[] { "Id", "CreatedAt", "CreatedBy", "Instruction", "IsDeleted", "Label", "Locale", "TemplatePhotoSettingId", "UpdatedAt", "UpdatedBy" },
                values: new object[,]
                {
                    { new Guid("44444444-0001-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Bitte laden Sie vier Fotos des Fahrzeugs von jeder Ecke hoch.", false, "Fahrzeugfotos", "de", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0001-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Carica quattro foto del veicolo da ciascun angolo.", false, "Foto del veicolo", "it", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0001-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Veuillez téléverser quatre photos du véhicule depuis chaque coin.", false, "Photos du véhicule", "fr", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0001-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Sube cuatro fotos del vehículo desde cada esquina.", false, "Fotos del vehículo", "es", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0001-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Prześlij cztery zdjęcia pojazdu z każdego rogu.", false, "Zdjęcia pojazdu", "pl", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0001-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Įkelkite keturias transporto priemonės nuotraukas iš kiekvieno kampo.", false, "Transporto priemonės nuotraukos", "lt", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0001-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Lūdzu, augšupielādējiet četras transportlīdzekļa fotogrāfijas no katra stūra.", false, "Transportlīdzekļa fotogrāfijas", "lv", new Guid("44444444-0001-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Laden Sie klare Fotos des Schadens aus mehreren Winkeln hoch.", false, "Schadensfotos", "de", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Carica foto chiare del danno da più angolazioni.", false, "Foto del danno", "it", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Téléversez des photos claires des dommages sous plusieurs angles.", false, "Photos des dommages", "fr", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Sube fotos claras del daño desde varios ángulos.", false, "Fotos del daño", "es", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Prześlij wyraźne zdjęcia uszkodzeń pod różnymi kątami.", false, "Zdjęcia uszkodzeń", "pl", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Įkelkite aiškias žalos nuotraukas iš kelių kampų.", false, "Žalos nuotraukos", "lt", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0002-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Augšupielādējiet skaidras bojājumu fotogrāfijas no vairākiem leņķiem.", false, "Bojājumu fotogrāfijas", "lv", new Guid("44444444-0002-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0001-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Laden Sie Vorder- und Rückseite des Führerscheins hoch.", false, "Führerschein", "de", new Guid("44444444-0003-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0002-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Carica fronte e retro della patente di guida.", false, "Patente di guida", "it", new Guid("44444444-0003-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0003-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Téléversez le recto et le verso du permis de conduire.", false, "Permis de conduire", "fr", new Guid("44444444-0003-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0004-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Sube el anverso y el reverso de la licencia de conducir.", false, "Licencia de conducir", "es", new Guid("44444444-0003-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0005-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Prześlij przednią i tylną stronę prawa jazdy.", false, "Prawo jazdy", "pl", new Guid("44444444-0003-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0006-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Įkelkite vairuotojo pažymėjimo priekinę ir galinę puses.", false, "Vairuotojo pažymėjimas", "lt", new Guid("44444444-0003-0000-0000-000000000000"), null, null },
                    { new Guid("44444444-0003-0007-0000-000000000000"), new DateTime(2026, 4, 22, 0, 0, 0, 0, DateTimeKind.Utc), null, "Augšupielādējiet vadītāja apliecības priekšpusi un aizmuguri.", false, "Vadītāja apliecība", "lv", new Guid("44444444-0003-0000-0000-000000000000"), null, null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_TemplateDocumentSettingTranslations_TemplateDocumentSetting~",
                table: "TemplateDocumentSettingTranslations",
                columns: new[] { "TemplateDocumentSettingId", "Locale" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_TemplateIdentityFieldTranslations_TemplateIdentityFieldId_L~",
                table: "TemplateIdentityFieldTranslations",
                columns: new[] { "TemplateIdentityFieldId", "Locale" },
                unique: true,
                filter: "\"IsDeleted\" = false");

            migrationBuilder.CreateIndex(
                name: "IX_TemplatePhotoSettingTranslations_TemplatePhotoSettingId_Loc~",
                table: "TemplatePhotoSettingTranslations",
                columns: new[] { "TemplatePhotoSettingId", "Locale" },
                unique: true,
                filter: "\"IsDeleted\" = false");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TemplateDocumentSettingTranslations");

            migrationBuilder.DropTable(
                name: "TemplateIdentityFieldTranslations");

            migrationBuilder.DropTable(
                name: "TemplatePhotoSettingTranslations");
        }
    }
}
