using ClaimAI.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class NotificationTemplateConfiguration : IEntityTypeConfiguration<NotificationTemplate>
{
    internal static readonly DateTime SeedTimestamp =
        new(2026, 6, 11, 0, 0, 0, DateTimeKind.Utc);

    // Stable parent IDs — kept in sync with NotificationTemplateTranslationConfiguration.
    internal static readonly Guid StatusInReviewId =
        new("55555555-0001-0000-0000-000000000000");
    internal static readonly Guid StatusApprovedId =
        new("55555555-0002-0000-0000-000000000000");
    internal static readonly Guid StatusRejectedId =
        new("55555555-0003-0000-0000-000000000000");
    internal static readonly Guid ActionUploadPhotosAndDocsId =
        new("55555555-0004-0000-0000-000000000000");
    internal static readonly Guid ActionUploadPhotosId =
        new("55555555-0005-0000-0000-000000000000");
    internal static readonly Guid ActionUploadDocsId =
        new("55555555-0006-0000-0000-000000000000");

    public void Configure(EntityTypeBuilder<NotificationTemplate> builder)
    {
        builder.Property(t => t.Key).IsRequired().HasMaxLength(80);
        builder.Property(t => t.DefaultTitle).IsRequired().HasMaxLength(200);
        builder.Property(t => t.DefaultMessage).IsRequired().HasMaxLength(500);

        builder.HasIndex(t => t.Key)
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        var ts = SeedTimestamp;

        builder.HasData(
            Seed(StatusInReviewId, "claim.status.inReview",
                "Claim {claimNumber} updated",
                "Your claim is now under review.{noteSuffix}", ts),
            Seed(StatusApprovedId, "claim.status.approved",
                "Claim {claimNumber} updated",
                "Your claim has been approved.{noteSuffix}", ts),
            Seed(StatusRejectedId, "claim.status.rejected",
                "Claim {claimNumber} updated",
                "Your claim has been rejected.{noteSuffix}", ts),
            Seed(ActionUploadPhotosAndDocsId, "claim.action.uploadPhotosAndDocs",
                "Action Required",
                "Please upload photos and supporting documents to complete your claim {claimNumber}.", ts),
            Seed(ActionUploadPhotosId, "claim.action.uploadPhotos",
                "Action Required",
                "Please upload photos of the damage to complete your claim {claimNumber}.", ts),
            Seed(ActionUploadDocsId, "claim.action.uploadDocs",
                "Action Required",
                "Please upload supporting documents to complete your claim {claimNumber}.", ts));
    }

    private static NotificationTemplate Seed(
        Guid id, string key, string defaultTitle, string defaultMessage, DateTime ts)
        => new()
        {
            Id = id,
            Key = key,
            DefaultTitle = defaultTitle,
            DefaultMessage = defaultMessage,
            CreatedAt = ts,
            IsDeleted = false,
        };
}
