using ClaimAI.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class ClaimDocumentConfiguration : IEntityTypeConfiguration<ClaimDocument>
{
    public void Configure(EntityTypeBuilder<ClaimDocument> builder)
    {
        builder.Property(d => d.UserId).IsRequired();
        builder.Property(d => d.FileName).IsRequired().HasMaxLength(260);
        builder.Property(d => d.StoredFileName).IsRequired().HasMaxLength(260);
        builder.Property(d => d.RelativeUrl).IsRequired().HasMaxLength(512);
        builder.Property(d => d.ContentType).IsRequired().HasMaxLength(100);
        builder.Property(d => d.Kind).IsRequired().HasMaxLength(20);
        builder.Property(d => d.GroupKey).HasMaxLength(60);
        builder.Property(d => d.Label).HasMaxLength(120);
        builder.Property(d => d.Angle).HasMaxLength(40);
        builder.Property(d => d.ChatThreadId).HasMaxLength(64);

        builder.HasOne(d => d.User)
               .WithMany()
               .HasForeignKey(d => d.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(d => d.Claim)
               .WithMany()
               .HasForeignKey(d => d.ClaimId)
               .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(d => d.ClaimId);
        builder.HasIndex(d => new { d.UserId, d.ChatThreadId });
    }
}
