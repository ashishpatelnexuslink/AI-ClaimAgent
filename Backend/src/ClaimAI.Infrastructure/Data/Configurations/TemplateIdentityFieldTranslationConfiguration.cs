using ClaimAI.Domain.Entities.Templates;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplateIdentityFieldTranslationConfiguration
    : IEntityTypeConfiguration<TemplateIdentityFieldTranslation>
{
    public void Configure(EntityTypeBuilder<TemplateIdentityFieldTranslation> builder)
    {
        builder.Property(t => t.TemplateIdentityFieldId).IsRequired();
        builder.Property(t => t.Locale).IsRequired().HasMaxLength(10);
        builder.Property(t => t.Label).IsRequired().HasMaxLength(150);
        builder.Property(t => t.PromptText).IsRequired();
        builder.Property(t => t.Placeholder);

        builder.HasOne(t => t.TemplateIdentityField)
               .WithMany(f => f.Translations)
               .HasForeignKey(t => t.TemplateIdentityFieldId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(t => new { t.TemplateIdentityFieldId, t.Locale })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        // No HasData seed: identity fields are admin-created (the seed
        // template ships with none), so translations are added through the
        // AdminPanel after the field itself exists.
    }
}
