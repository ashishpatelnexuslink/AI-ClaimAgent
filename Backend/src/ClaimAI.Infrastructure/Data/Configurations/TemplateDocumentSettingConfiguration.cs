using ClaimAI.Domain.Entities.Templates;
using ClaimAI.Infrastructure.Data.Converters;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplateDocumentSettingConfiguration : IEntityTypeConfiguration<TemplateDocumentSetting>
{
    public void Configure(EntityTypeBuilder<TemplateDocumentSetting> builder)
    {
        builder.Property(d => d.TemplateId).IsRequired();
        builder.Property(d => d.DocKey).IsRequired().HasMaxLength(60);
        builder.Property(d => d.Label).IsRequired().HasMaxLength(150);
        builder.Property(d => d.Instruction);

        builder.Property(d => d.MinCount).IsRequired();
        builder.Property(d => d.MaxCount).IsRequired();
        builder.Property(d => d.IsRequired).IsRequired().HasDefaultValue(true);

        builder.Property(d => d.AllowedMimeTypes).HasJsonbStringListConversion().IsRequired();

        builder.Property(d => d.MaxFileSizeMb).IsRequired().HasDefaultValue(10);
        builder.Property(d => d.DisplayOrder).IsRequired();

        builder.HasOne(d => d.Template)
               .WithMany(t => t.DocumentSettings)
               .HasForeignKey(d => d.TemplateId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(d => new { d.TemplateId, d.DocKey })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        builder.ToTable(t =>
        {
            t.HasCheckConstraint(
                "CK_TemplateDocumentSettings_CountRange",
                "\"MinCount\" >= 0 AND \"MaxCount\" >= \"MinCount\"");
            t.HasCheckConstraint(
                "CK_TemplateDocumentSettings_FileSize",
                "\"MaxFileSizeMb\" BETWEEN 1 AND 100");
        });

        var ts = TemplateConfiguration.SeedTimestamp;
        var tid = TemplateConfiguration.SeedTemplateId;
        var pdfJpegPng = new List<string> { "application/pdf", "image/jpeg", "image/png" };

        builder.HasData(
            new TemplateDocumentSetting
            {
                Id = new Guid("55555555-0001-0000-0000-000000000000"),
                TemplateId = tid,
                DocKey = "bill_invoice",
                Label = "Bill / Invoice",
                Instruction = "Upload the repair bill or invoice.",
                MinCount = 1,
                MaxCount = 2,
                IsRequired = false,
                MaxFileSizeMb = 10,
                AllowedMimeTypes = pdfJpegPng,
                DisplayOrder = 1,
                CreatedAt = ts,
                IsDeleted = false
            },
            new TemplateDocumentSetting
            {
                Id = new Guid("55555555-0002-0000-0000-000000000000"),
                TemplateId = tid,
                DocKey = "insurance_policy",
                Label = "Insurance Policy",
                Instruction = "Upload the current insurance policy document.",
                MinCount = 1,
                MaxCount = 1,
                IsRequired = true,
                MaxFileSizeMb = 10,
                AllowedMimeTypes = pdfJpegPng,
                DisplayOrder = 2,
                CreatedAt = ts,
                IsDeleted = false
            },
            new TemplateDocumentSetting
            {
                Id = new Guid("55555555-0003-0000-0000-000000000000"),
                TemplateId = tid,
                DocKey = "police_report",
                Label = "Police Report",
                Instruction = "If available, upload the police report.",
                MinCount = 0,
                MaxCount = 1,
                IsRequired = false,
                MaxFileSizeMb = 10,
                AllowedMimeTypes = pdfJpegPng,
                DisplayOrder = 3,
                CreatedAt = ts,
                IsDeleted = false
            },
            new TemplateDocumentSetting
            {
                Id = new Guid("55555555-0004-0000-0000-000000000000"),
                TemplateId = tid,
                DocKey = "supporting_docs",
                Label = "Supporting Documents",
                Instruction = "Upload any additional supporting documents.",
                MinCount = 0,
                MaxCount = 10,
                IsRequired = false,
                MaxFileSizeMb = 10,
                AllowedMimeTypes = pdfJpegPng,
                DisplayOrder = 4,
                CreatedAt = ts,
                IsDeleted = false
            });
    }
}
