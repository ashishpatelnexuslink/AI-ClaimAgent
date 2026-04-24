using ClaimAI.Domain.Entities.Templates;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplateIdentityFieldConfiguration : IEntityTypeConfiguration<TemplateIdentityField>
{
    public void Configure(EntityTypeBuilder<TemplateIdentityField> builder)
    {
        builder.Property(f => f.TemplateId).IsRequired();

        builder.Property(f => f.FieldKey).IsRequired().HasMaxLength(60);
        builder.Property(f => f.Label).IsRequired().HasMaxLength(150);
        builder.Property(f => f.PromptText).IsRequired();
        builder.Property(f => f.Placeholder).HasMaxLength(150);
        builder.Property(f => f.ValidationRegex).HasMaxLength(500);
        builder.Property(f => f.GroupKey).HasMaxLength(60);
        builder.Property(f => f.IsSkippable).IsRequired().HasDefaultValue(false);
        builder.Property(f => f.DisplayOrder).IsRequired();

        builder.HasOne(f => f.Template)
               .WithMany(t => t.IdentityFields)
               .HasForeignKey(f => f.TemplateId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(f => new { f.TemplateId, f.FieldKey })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        builder.HasIndex(f => new { f.TemplateId, f.DisplayOrder });

        var ts = TemplateConfiguration.SeedTimestamp;
        var tid = TemplateConfiguration.SeedTemplateId;

        builder.HasData(
            new TemplateIdentityField
            {
                Id = new Guid("22222222-0001-0000-0000-000000000000"),
                TemplateId = tid,
                FieldKey = "full_name",
                Label = "Full Name",
                PromptText = "Kindly provide your full name as per official records.",
                Placeholder = null,
                ValidationRegex = null,
                GroupKey = null,
                IsSkippable = false,
                DisplayOrder = 1,
                CreatedAt = ts,
                IsDeleted = false
            },
            new TemplateIdentityField
            {
                Id = new Guid("22222222-0002-0000-0000-000000000000"),
                TemplateId = tid,
                FieldKey = "vehicle_reg",
                Label = "Vehicle Registration No.",
                PromptText = "Please provide your vehicle registration number.",
                GroupKey = "vehicle_identity",
                IsSkippable = true,
                DisplayOrder = 2,
                CreatedAt = ts,
                IsDeleted = false
            },
            new TemplateIdentityField
            {
                Id = new Guid("22222222-0003-0000-0000-000000000000"),
                TemplateId = tid,
                FieldKey = "policy_number",
                Label = "Policy Number",
                PromptText = "Please provide your insurance policy number for verification.",
                GroupKey = "vehicle_identity",
                IsSkippable = true,
                DisplayOrder = 3,
                CreatedAt = ts,
                IsDeleted = false
            },
            new TemplateIdentityField
            {
                Id = new Guid("22222222-0004-0000-0000-000000000000"),
                TemplateId = tid,
                FieldKey = "vin",
                Label = "VIN Number",
                PromptText = "Please provide the Vehicle Identification Number (VIN).",
                GroupKey = "vehicle_identity",
                IsSkippable = true,
                DisplayOrder = 4,
                CreatedAt = ts,
                IsDeleted = false
            });
    }
}
