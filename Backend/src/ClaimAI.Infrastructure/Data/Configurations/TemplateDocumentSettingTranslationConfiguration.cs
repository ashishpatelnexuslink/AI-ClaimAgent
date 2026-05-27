using ClaimAI.Domain.Entities.Templates;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplateDocumentSettingTranslationConfiguration
    : IEntityTypeConfiguration<TemplateDocumentSettingTranslation>
{
    public void Configure(EntityTypeBuilder<TemplateDocumentSettingTranslation> builder)
    {
        builder.Property(t => t.TemplateDocumentSettingId).IsRequired();
        builder.Property(t => t.Locale).IsRequired().HasMaxLength(10);
        builder.Property(t => t.Label).IsRequired().HasMaxLength(150);
        builder.Property(t => t.Instruction);

        builder.HasOne(t => t.TemplateDocumentSetting)
               .WithMany(d => d.Translations)
               .HasForeignKey(t => t.TemplateDocumentSettingId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(t => new { t.TemplateDocumentSettingId, t.Locale })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        var ts = TemplateConfiguration.SeedTimestamp;

        // Parent IDs (kept in sync with TemplateDocumentSettingConfiguration.HasData):
        //   55555555-0001-...  bill_invoice
        //   55555555-0002-...  insurance_policy
        //   55555555-0003-...  police_report
        //   55555555-0004-...  supporting_docs
        var billId       = new Guid("55555555-0001-0000-0000-000000000000");
        var policyId     = new Guid("55555555-0002-0000-0000-000000000000");
        var policeId     = new Guid("55555555-0003-0000-0000-000000000000");
        var supportingId = new Guid("55555555-0004-0000-0000-000000000000");

        builder.HasData(
            // ── bill_invoice ────────────────────────────────────────────
            Seed("55555555-0001-0001", billId, "de", "Rechnung / Beleg",
                "Laden Sie die Reparaturrechnung oder den Beleg hoch.", ts),
            Seed("55555555-0001-0002", billId, "it", "Fattura / Ricevuta",
                "Carica la fattura della riparazione o la ricevuta.", ts),
            Seed("55555555-0001-0003", billId, "fr", "Facture / Reçu",
                "Téléversez la facture ou le reçu de la réparation.", ts),
            Seed("55555555-0001-0004", billId, "es", "Factura / Recibo",
                "Sube la factura o el recibo de la reparación.", ts),
            Seed("55555555-0001-0005", billId, "pl", "Rachunek / Faktura",
                "Prześlij rachunek lub fakturę za naprawę.", ts),
            Seed("55555555-0001-0006", billId, "lt", "Sąskaita / Kvitas",
                "Įkelkite remonto sąskaitą arba kvitą.", ts),
            Seed("55555555-0001-0007", billId, "lv", "Rēķins / Kvīts",
                "Augšupielādējiet remonta rēķinu vai kvīti.", ts),

            // ── insurance_policy ────────────────────────────────────────
            Seed("55555555-0002-0001", policyId, "de", "Versicherungspolice",
                "Laden Sie das aktuelle Versicherungsdokument hoch.", ts),
            Seed("55555555-0002-0002", policyId, "it", "Polizza assicurativa",
                "Carica il documento attuale della polizza assicurativa.", ts),
            Seed("55555555-0002-0003", policyId, "fr", "Police d'assurance",
                "Téléversez le document de police d'assurance en cours.", ts),
            Seed("55555555-0002-0004", policyId, "es", "Póliza de seguro",
                "Sube el documento de la póliza de seguro vigente.", ts),
            Seed("55555555-0002-0005", policyId, "pl", "Polisa ubezpieczeniowa",
                "Prześlij aktualny dokument polisy ubezpieczeniowej.", ts),
            Seed("55555555-0002-0006", policyId, "lt", "Draudimo polisas",
                "Įkelkite galiojantį draudimo poliso dokumentą.", ts),
            Seed("55555555-0002-0007", policyId, "lv", "Apdrošināšanas polise",
                "Augšupielādējiet pašreizējo apdrošināšanas polises dokumentu.", ts),

            // ── police_report ───────────────────────────────────────────
            Seed("55555555-0003-0001", policeId, "de", "Polizeibericht",
                "Falls vorhanden, laden Sie den Polizeibericht hoch.", ts),
            Seed("55555555-0003-0002", policeId, "it", "Rapporto di polizia",
                "Se disponibile, carica il rapporto della polizia.", ts),
            Seed("55555555-0003-0003", policeId, "fr", "Rapport de police",
                "Si disponible, téléversez le rapport de police.", ts),
            Seed("55555555-0003-0004", policeId, "es", "Informe policial",
                "Si está disponible, sube el informe policial.", ts),
            Seed("55555555-0003-0005", policeId, "pl", "Raport policyjny",
                "Jeśli jest dostępny, prześlij raport policyjny.", ts),
            Seed("55555555-0003-0006", policeId, "lt", "Policijos ataskaita",
                "Jei turite, įkelkite policijos ataskaitą.", ts),
            Seed("55555555-0003-0007", policeId, "lv", "Policijas ziņojums",
                "Ja pieejams, augšupielādējiet policijas ziņojumu.", ts),

            // ── supporting_docs ─────────────────────────────────────────
            Seed("55555555-0004-0001", supportingId, "de", "Belege",
                "Laden Sie weitere unterstützende Dokumente hoch.", ts),
            Seed("55555555-0004-0002", supportingId, "it", "Documenti di supporto",
                "Carica eventuali altri documenti di supporto.", ts),
            Seed("55555555-0004-0003", supportingId, "fr", "Documents justificatifs",
                "Téléversez tout document justificatif supplémentaire.", ts),
            Seed("55555555-0004-0004", supportingId, "es", "Documentos de apoyo",
                "Sube cualquier documento de apoyo adicional.", ts),
            Seed("55555555-0004-0005", supportingId, "pl", "Dokumenty uzupełniające",
                "Prześlij wszelkie dodatkowe dokumenty uzupełniające.", ts),
            Seed("55555555-0004-0006", supportingId, "lt", "Papildomi dokumentai",
                "Įkelkite bet kokius papildomus pagrindžiančius dokumentus.", ts),
            Seed("55555555-0004-0007", supportingId, "lv", "Pavaddokumenti",
                "Augšupielādējiet jebkurus papildu pavaddokumentus.", ts));
    }

    private static TemplateDocumentSettingTranslation Seed(
        string idStem, Guid parentId, string locale, string label, string instruction, DateTime ts)
        => new()
        {
            Id = new Guid($"{idStem}-0000-000000000000"),
            TemplateDocumentSettingId = parentId,
            Locale = locale,
            Label = label,
            Instruction = instruction,
            CreatedAt = ts,
            IsDeleted = false,
        };
}
