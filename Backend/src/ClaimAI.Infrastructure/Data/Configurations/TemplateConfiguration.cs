using ClaimAI.Domain.Entities.Templates;
using ClaimAI.Domain.Enums;
using ClaimAI.Infrastructure.Data.Converters;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplateConfiguration : IEntityTypeConfiguration<Template>
{
    internal static readonly DateTime SeedTimestamp = new(2026, 4, 22, 0, 0, 0, DateTimeKind.Utc);
    internal static readonly Guid SeedTemplateId = new("11111111-1111-1111-1111-111111111111");

    public void Configure(EntityTypeBuilder<Template> builder)
    {
        builder.Property(t => t.CompanyName)
               .IsRequired()
               .HasMaxLength(200);

        builder.Property(t => t.InsuranceType)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(20);

        builder.Property(t => t.Name)
               .IsRequired()
               .HasMaxLength(200);

        builder.Property(t => t.Version)
               .IsRequired()
               .HasDefaultValue(1);

        builder.Property(t => t.Status)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(20)
               .HasDefaultValue(TemplateStatus.Draft);

        builder.Property(t => t.ClaimantTypes)
               .HasJsonbEnumListConversion<ClaimantType>()
               .IsRequired();

        builder.Property(t => t.RequireIncidentDt).IsRequired().HasDefaultValue(true);
        builder.Property(t => t.RequireLocation).IsRequired().HasDefaultValue(true);
        builder.Property(t => t.MinDescriptionLen).IsRequired().HasDefaultValue(40);

        // Unique: at most one row per (CompanyName, InsuranceType, Version) among live rows.
        builder.HasIndex(t => new { t.CompanyName, t.InsuranceType, t.Version })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        // Unique: at most one Active row per (CompanyName, InsuranceType).
        // Partial unique index enforces the "single active version" invariant at the DB level.
        builder.HasIndex(t => new { t.CompanyName, t.InsuranceType })
               .IsUnique()
               .HasDatabaseName("IX_Templates_Active_Singleton")
               .HasFilter("\"Status\" = 'Active' AND \"IsDeleted\" = false");

        builder.HasData(new Template
        {
            Id = SeedTemplateId,
            CompanyName = "Draudita Insurance",
            InsuranceType = InsuranceType.Motor,
            Name = "Draudita Motor Comprehensive",
            Version = 1,
            Status = TemplateStatus.Active,
            ClaimantTypes = new List<ClaimantType> { ClaimantType.PolicyHolder, ClaimantType.ThirdParty },
            RequireIncidentDt = true,
            RequireLocation = true,
            MinDescriptionLen = 40,
            CreatedAt = SeedTimestamp,
            IsDeleted = false
        });
    }
}
