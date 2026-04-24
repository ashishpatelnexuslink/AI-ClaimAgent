using ClaimAI.Domain.Entities.Templates;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplateFieldGroupRuleConfiguration : IEntityTypeConfiguration<TemplateFieldGroupRule>
{
    public void Configure(EntityTypeBuilder<TemplateFieldGroupRule> builder)
    {
        builder.Property(r => r.TemplateId).IsRequired();
        builder.Property(r => r.GroupKey).IsRequired().HasMaxLength(60);
        builder.Property(r => r.MinRequired).IsRequired();
        builder.Property(r => r.MaxAllowed);
        builder.Property(r => r.ErrorMessage).IsRequired();

        builder.HasOne(r => r.Template)
               .WithMany(t => t.GroupRules)
               .HasForeignKey(r => r.TemplateId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(r => new { r.TemplateId, r.GroupKey })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        builder.ToTable(t =>
        {
            t.HasCheckConstraint(
                "CK_TemplateFieldGroupRules_MinNonNegative",
                "\"MinRequired\" >= 0");
            t.HasCheckConstraint(
                "CK_TemplateFieldGroupRules_MaxGteMin",
                "\"MaxAllowed\" IS NULL OR \"MaxAllowed\" >= \"MinRequired\"");
        });

        var ts = TemplateConfiguration.SeedTimestamp;
        var tid = TemplateConfiguration.SeedTemplateId;

        builder.HasData(new TemplateFieldGroupRule
        {
            Id = new Guid("33333333-0001-0000-0000-000000000000"),
            TemplateId = tid,
            GroupKey = "vehicle_identity",
            MinRequired = 2,
            MaxAllowed = 3,
            ErrorMessage = "A minimum of two inputs is required. Kindly provide any of the following: Vehicle Registration Number, Vehicle Identification Number, or Vehicle Number.",
            CreatedAt = ts,
            IsDeleted = false
        });
    }
}
