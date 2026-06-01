using ClaimAI.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class AppVersionConfiguration : IEntityTypeConfiguration<AppVersion>
{
    public void Configure(EntityTypeBuilder<AppVersion> builder)
    {
        builder.ToTable("AppVersions");

        builder.Property(v => v.Platform)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(20);

        builder.Property(v => v.VersionName).IsRequired().HasMaxLength(50);
        builder.Property(v => v.VersionCode).IsRequired();
        builder.Property(v => v.MinSupportedVersionCode).IsRequired();
        builder.Property(v => v.IsLatest).HasDefaultValue(false);
        builder.Property(v => v.IsMandatory).HasDefaultValue(false);
        builder.Property(v => v.ReleaseNotes).HasMaxLength(4000);
        builder.Property(v => v.StoreUrl).HasMaxLength(500);

        // Unique (Platform, VersionCode) among live rows
        builder.HasIndex(v => new { v.Platform, v.VersionCode })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        // At most one IsLatest=true row per platform among live rows
        builder.HasIndex(v => v.Platform)
               .IsUnique()
               .HasDatabaseName("IX_AppVersions_Platform_IsLatest")
               .HasFilter("\"IsDeleted\" = false AND \"IsLatest\" = true");
    }
}
