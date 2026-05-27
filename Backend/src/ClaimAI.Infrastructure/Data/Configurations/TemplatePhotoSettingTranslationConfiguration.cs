using ClaimAI.Domain.Entities.Templates;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplatePhotoSettingTranslationConfiguration
    : IEntityTypeConfiguration<TemplatePhotoSettingTranslation>
{
    public void Configure(EntityTypeBuilder<TemplatePhotoSettingTranslation> builder)
    {
        builder.Property(t => t.TemplatePhotoSettingId).IsRequired();
        builder.Property(t => t.Locale).IsRequired().HasMaxLength(10);
        builder.Property(t => t.Label).IsRequired().HasMaxLength(150);
        builder.Property(t => t.Instruction);

        builder.HasOne(t => t.TemplatePhotoSetting)
               .WithMany(p => p.Translations)
               .HasForeignKey(t => t.TemplatePhotoSettingId)
               .OnDelete(DeleteBehavior.Cascade);

        // At most one row per (parent, locale) among live rows.
        builder.HasIndex(t => new { t.TemplatePhotoSettingId, t.Locale })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        var ts = TemplateConfiguration.SeedTimestamp;

        // Parent IDs (kept in sync with TemplatePhotoSettingConfiguration.HasData):
        //   44444444-0001-...  vehicle_photos  → "Vehicle Photos"
        //   44444444-0002-...  damage_photos   → "Damage Photos"
        //   44444444-0003-...  driver_license  → "Driver License"
        var vehicleId = new Guid("44444444-0001-0000-0000-000000000000");
        var damageId  = new Guid("44444444-0002-0000-0000-000000000000");
        var licenseId = new Guid("44444444-0003-0000-0000-000000000000");

        // Deterministic translation IDs follow the parent ID pattern with a
        // locale-bucketed third group so future locales slot in cleanly.
        builder.HasData(
            // ── vehicle_photos ──────────────────────────────────────────
            Seed("44444444-0001-0001", vehicleId, "de",
                "Fahrzeugfotos",
                "Bitte laden Sie vier Fotos des Fahrzeugs von jeder Ecke hoch.", ts),
            Seed("44444444-0001-0002", vehicleId, "it",
                "Foto del veicolo",
                "Carica quattro foto del veicolo da ciascun angolo.", ts),
            Seed("44444444-0001-0003", vehicleId, "fr",
                "Photos du véhicule",
                "Veuillez téléverser quatre photos du véhicule depuis chaque coin.", ts),
            Seed("44444444-0001-0004", vehicleId, "es",
                "Fotos del vehículo",
                "Sube cuatro fotos del vehículo desde cada esquina.", ts),
            Seed("44444444-0001-0005", vehicleId, "pl",
                "Zdjęcia pojazdu",
                "Prześlij cztery zdjęcia pojazdu z każdego rogu.", ts),
            Seed("44444444-0001-0006", vehicleId, "lt",
                "Transporto priemonės nuotraukos",
                "Įkelkite keturias transporto priemonės nuotraukas iš kiekvieno kampo.", ts),
            Seed("44444444-0001-0007", vehicleId, "lv",
                "Transportlīdzekļa fotogrāfijas",
                "Lūdzu, augšupielādējiet četras transportlīdzekļa fotogrāfijas no katra stūra.", ts),

            // ── damage_photos ──────────────────────────────────────────
            Seed("44444444-0002-0001", damageId, "de",
                "Schadensfotos",
                "Laden Sie klare Fotos des Schadens aus mehreren Winkeln hoch.", ts),
            Seed("44444444-0002-0002", damageId, "it",
                "Foto del danno",
                "Carica foto chiare del danno da più angolazioni.", ts),
            Seed("44444444-0002-0003", damageId, "fr",
                "Photos des dommages",
                "Téléversez des photos claires des dommages sous plusieurs angles.", ts),
            Seed("44444444-0002-0004", damageId, "es",
                "Fotos del daño",
                "Sube fotos claras del daño desde varios ángulos.", ts),
            Seed("44444444-0002-0005", damageId, "pl",
                "Zdjęcia uszkodzeń",
                "Prześlij wyraźne zdjęcia uszkodzeń pod różnymi kątami.", ts),
            Seed("44444444-0002-0006", damageId, "lt",
                "Žalos nuotraukos",
                "Įkelkite aiškias žalos nuotraukas iš kelių kampų.", ts),
            Seed("44444444-0002-0007", damageId, "lv",
                "Bojājumu fotogrāfijas",
                "Augšupielādējiet skaidras bojājumu fotogrāfijas no vairākiem leņķiem.", ts),

            // ── driver_license ──────────────────────────────────────────
            Seed("44444444-0003-0001", licenseId, "de",
                "Führerschein",
                "Laden Sie Vorder- und Rückseite des Führerscheins hoch.", ts),
            Seed("44444444-0003-0002", licenseId, "it",
                "Patente di guida",
                "Carica fronte e retro della patente di guida.", ts),
            Seed("44444444-0003-0003", licenseId, "fr",
                "Permis de conduire",
                "Téléversez le recto et le verso du permis de conduire.", ts),
            Seed("44444444-0003-0004", licenseId, "es",
                "Licencia de conducir",
                "Sube el anverso y el reverso de la licencia de conducir.", ts),
            Seed("44444444-0003-0005", licenseId, "pl",
                "Prawo jazdy",
                "Prześlij przednią i tylną stronę prawa jazdy.", ts),
            Seed("44444444-0003-0006", licenseId, "lt",
                "Vairuotojo pažymėjimas",
                "Įkelkite vairuotojo pažymėjimo priekinę ir galinę puses.", ts),
            Seed("44444444-0003-0007", licenseId, "lv",
                "Vadītāja apliecība",
                "Augšupielādējiet vadītāja apliecības priekšpusi un aizmuguri.", ts));
    }

    private static TemplatePhotoSettingTranslation Seed(
        string idStem, Guid parentId, string locale, string label, string instruction, DateTime ts)
        => new()
        {
            Id = new Guid($"{idStem}-0000-000000000000"),
            TemplatePhotoSettingId = parentId,
            Locale = locale,
            Label = label,
            Instruction = instruction,
            CreatedAt = ts,
            IsDeleted = false,
        };
}
