using ClaimAI.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class NotificationTemplateTranslationConfiguration
    : IEntityTypeConfiguration<NotificationTemplateTranslation>
{
    public void Configure(EntityTypeBuilder<NotificationTemplateTranslation> builder)
    {
        builder.Property(t => t.NotificationTemplateId).IsRequired();
        builder.Property(t => t.Locale).IsRequired().HasMaxLength(10);
        builder.Property(t => t.Title).IsRequired().HasMaxLength(200);
        builder.Property(t => t.Message).IsRequired().HasMaxLength(500);

        builder.HasOne(t => t.NotificationTemplate)
               .WithMany(p => p.Translations)
               .HasForeignKey(t => t.NotificationTemplateId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(t => new { t.NotificationTemplateId, t.Locale })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        var ts = NotificationTemplateConfiguration.SeedTimestamp;

        var statusInReview = NotificationTemplateConfiguration.StatusInReviewId;
        var statusApproved = NotificationTemplateConfiguration.StatusApprovedId;
        var statusRejected = NotificationTemplateConfiguration.StatusRejectedId;
        var uploadBoth = NotificationTemplateConfiguration.ActionUploadPhotosAndDocsId;
        var uploadPhotos = NotificationTemplateConfiguration.ActionUploadPhotosId;
        var uploadDocs = NotificationTemplateConfiguration.ActionUploadDocsId;

        builder.HasData(
            // ── claim.status.inReview ──────────────────────────────────
            Seed("55555555-0001-0001", statusInReview, "de",
                "Schaden {claimNumber} aktualisiert",
                "Ihr Schaden wird jetzt geprüft.{noteSuffix}", ts),
            Seed("55555555-0001-0002", statusInReview, "es",
                "Siniestro {claimNumber} actualizado",
                "Su siniestro está ahora en revisión.{noteSuffix}", ts),
            Seed("55555555-0001-0003", statusInReview, "fr",
                "Sinistre {claimNumber} mis à jour",
                "Votre sinistre est désormais en cours d'examen.{noteSuffix}", ts),
            Seed("55555555-0001-0004", statusInReview, "it",
                "Sinistro {claimNumber} aggiornato",
                "Il tuo sinistro è ora in revisione.{noteSuffix}", ts),
            Seed("55555555-0001-0005", statusInReview, "lt",
                "Žala {claimNumber} atnaujinta",
                "Jūsų žala dabar peržiūrima.{noteSuffix}", ts),
            Seed("55555555-0001-0006", statusInReview, "lv",
                "Prasība {claimNumber} atjaunināta",
                "Jūsu prasība pašlaik tiek izskatīta.{noteSuffix}", ts),
            Seed("55555555-0001-0007", statusInReview, "pl",
                "Roszczenie {claimNumber} zaktualizowane",
                "Twoje roszczenie jest teraz weryfikowane.{noteSuffix}", ts),

            // ── claim.status.approved ──────────────────────────────────
            Seed("55555555-0002-0001", statusApproved, "de",
                "Schaden {claimNumber} aktualisiert",
                "Ihr Schaden wurde genehmigt.{noteSuffix}", ts),
            Seed("55555555-0002-0002", statusApproved, "es",
                "Siniestro {claimNumber} actualizado",
                "Su siniestro ha sido aprobado.{noteSuffix}", ts),
            Seed("55555555-0002-0003", statusApproved, "fr",
                "Sinistre {claimNumber} mis à jour",
                "Votre sinistre a été approuvé.{noteSuffix}", ts),
            Seed("55555555-0002-0004", statusApproved, "it",
                "Sinistro {claimNumber} aggiornato",
                "Il tuo sinistro è stato approvato.{noteSuffix}", ts),
            Seed("55555555-0002-0005", statusApproved, "lt",
                "Žala {claimNumber} atnaujinta",
                "Jūsų žala patvirtinta.{noteSuffix}", ts),
            Seed("55555555-0002-0006", statusApproved, "lv",
                "Prasība {claimNumber} atjaunināta",
                "Jūsu prasība ir apstiprināta.{noteSuffix}", ts),
            Seed("55555555-0002-0007", statusApproved, "pl",
                "Roszczenie {claimNumber} zaktualizowane",
                "Twoje roszczenie zostało zatwierdzone.{noteSuffix}", ts),

            // ── claim.status.rejected ──────────────────────────────────
            Seed("55555555-0003-0001", statusRejected, "de",
                "Schaden {claimNumber} aktualisiert",
                "Ihr Schaden wurde abgelehnt.{noteSuffix}", ts),
            Seed("55555555-0003-0002", statusRejected, "es",
                "Siniestro {claimNumber} actualizado",
                "Su siniestro ha sido rechazado.{noteSuffix}", ts),
            Seed("55555555-0003-0003", statusRejected, "fr",
                "Sinistre {claimNumber} mis à jour",
                "Votre sinistre a été rejeté.{noteSuffix}", ts),
            Seed("55555555-0003-0004", statusRejected, "it",
                "Sinistro {claimNumber} aggiornato",
                "Il tuo sinistro è stato rifiutato.{noteSuffix}", ts),
            Seed("55555555-0003-0005", statusRejected, "lt",
                "Žala {claimNumber} atnaujinta",
                "Jūsų žala atmesta.{noteSuffix}", ts),
            Seed("55555555-0003-0006", statusRejected, "lv",
                "Prasība {claimNumber} atjaunināta",
                "Jūsu prasība ir noraidīta.{noteSuffix}", ts),
            Seed("55555555-0003-0007", statusRejected, "pl",
                "Roszczenie {claimNumber} zaktualizowane",
                "Twoje roszczenie zostało odrzucone.{noteSuffix}", ts),

            // ── claim.action.uploadPhotosAndDocs ───────────────────────
            Seed("55555555-0004-0001", uploadBoth, "de",
                "Aktion erforderlich",
                "Bitte laden Sie Fotos und Belege hoch, um Ihren Schaden {claimNumber} abzuschließen.", ts),
            Seed("55555555-0004-0002", uploadBoth, "es",
                "Acción requerida",
                "Sube fotos y documentos de respaldo para completar tu siniestro {claimNumber}.", ts),
            Seed("55555555-0004-0003", uploadBoth, "fr",
                "Action requise",
                "Veuillez téléverser des photos et des justificatifs pour compléter votre sinistre {claimNumber}.", ts),
            Seed("55555555-0004-0004", uploadBoth, "it",
                "Azione richiesta",
                "Carica foto e documenti di supporto per completare il tuo sinistro {claimNumber}.", ts),
            Seed("55555555-0004-0005", uploadBoth, "lt",
                "Reikalingas veiksmas",
                "Įkelkite nuotraukas ir patvirtinamuosius dokumentus, kad užbaigtumėte žalą {claimNumber}.", ts),
            Seed("55555555-0004-0006", uploadBoth, "lv",
                "Nepieciešama darbība",
                "Lūdzu, augšupielādējiet fotogrāfijas un pamatojuma dokumentus, lai pabeigtu prasību {claimNumber}.", ts),
            Seed("55555555-0004-0007", uploadBoth, "pl",
                "Wymagane działanie",
                "Prześlij zdjęcia i dokumenty potwierdzające, aby ukończyć roszczenie {claimNumber}.", ts),

            // ── claim.action.uploadPhotos ──────────────────────────────
            Seed("55555555-0005-0001", uploadPhotos, "de",
                "Aktion erforderlich",
                "Bitte laden Sie Fotos des Schadens hoch, um Ihren Schaden {claimNumber} abzuschließen.", ts),
            Seed("55555555-0005-0002", uploadPhotos, "es",
                "Acción requerida",
                "Sube fotos del daño para completar tu siniestro {claimNumber}.", ts),
            Seed("55555555-0005-0003", uploadPhotos, "fr",
                "Action requise",
                "Veuillez téléverser des photos des dommages pour compléter votre sinistre {claimNumber}.", ts),
            Seed("55555555-0005-0004", uploadPhotos, "it",
                "Azione richiesta",
                "Carica foto del danno per completare il tuo sinistro {claimNumber}.", ts),
            Seed("55555555-0005-0005", uploadPhotos, "lt",
                "Reikalingas veiksmas",
                "Įkelkite žalos nuotraukas, kad užbaigtumėte žalą {claimNumber}.", ts),
            Seed("55555555-0005-0006", uploadPhotos, "lv",
                "Nepieciešama darbība",
                "Lūdzu, augšupielādējiet bojājumu fotogrāfijas, lai pabeigtu prasību {claimNumber}.", ts),
            Seed("55555555-0005-0007", uploadPhotos, "pl",
                "Wymagane działanie",
                "Prześlij zdjęcia uszkodzeń, aby ukończyć roszczenie {claimNumber}.", ts),

            // ── claim.action.uploadDocs ────────────────────────────────
            Seed("55555555-0006-0001", uploadDocs, "de",
                "Aktion erforderlich",
                "Bitte laden Sie Belege hoch, um Ihren Schaden {claimNumber} abzuschließen.", ts),
            Seed("55555555-0006-0002", uploadDocs, "es",
                "Acción requerida",
                "Sube documentos de respaldo para completar tu siniestro {claimNumber}.", ts),
            Seed("55555555-0006-0003", uploadDocs, "fr",
                "Action requise",
                "Veuillez téléverser des justificatifs pour compléter votre sinistre {claimNumber}.", ts),
            Seed("55555555-0006-0004", uploadDocs, "it",
                "Azione richiesta",
                "Carica documenti di supporto per completare il tuo sinistro {claimNumber}.", ts),
            Seed("55555555-0006-0005", uploadDocs, "lt",
                "Reikalingas veiksmas",
                "Įkelkite patvirtinamuosius dokumentus, kad užbaigtumėte žalą {claimNumber}.", ts),
            Seed("55555555-0006-0006", uploadDocs, "lv",
                "Nepieciešama darbība",
                "Lūdzu, augšupielādējiet pamatojuma dokumentus, lai pabeigtu prasību {claimNumber}.", ts),
            Seed("55555555-0006-0007", uploadDocs, "pl",
                "Wymagane działanie",
                "Prześlij dokumenty potwierdzające, aby ukończyć roszczenie {claimNumber}.", ts));
    }

    private static NotificationTemplateTranslation Seed(
        string idStem, Guid parentId, string locale, string title, string message, DateTime ts)
        => new()
        {
            Id = new Guid($"{idStem}-0000-000000000000"),
            NotificationTemplateId = parentId,
            Locale = locale,
            Title = title,
            Message = message,
            CreatedAt = ts,
            IsDeleted = false,
        };
}
