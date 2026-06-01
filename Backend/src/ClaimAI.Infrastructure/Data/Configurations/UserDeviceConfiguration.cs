using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.Property(d => d.UserId).IsRequired().HasMaxLength(450);
        builder.Property(d => d.FcmToken).IsRequired().HasMaxLength(512);
        builder.Property(d => d.Platform)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(20);

        builder.HasOne(d => d.User)
               .WithMany()
               .HasForeignKey(d => d.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(d => d.UserId);

        // Unique among live (non-soft-deleted) rows
        builder.HasIndex(d => d.FcmToken)
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");
    }
}
