using ClaimAI.Domain.Entities.Templates;
using ClaimAI.Infrastructure.Data.Converters;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class TemplatePhotoSettingConfiguration : IEntityTypeConfiguration<TemplatePhotoSetting>
{
    public void Configure(EntityTypeBuilder<TemplatePhotoSetting> builder)
    {
        builder.Property(p => p.TemplateId).IsRequired();
        builder.Property(p => p.GroupKey).IsRequired().HasMaxLength(60);
        builder.Property(p => p.Label).IsRequired().HasMaxLength(150);
        builder.Property(p => p.Instruction);

        builder.Property(p => p.MinCount).IsRequired();
        builder.Property(p => p.MaxCount).IsRequired();
        builder.Property(p => p.IsRequired).IsRequired().HasDefaultValue(true);

        builder.Property(p => p.AllowedAngles).HasJsonbStringListConversion().IsRequired();
        builder.Property(p => p.SampleImageUrls).HasJsonbStringListConversion().IsRequired();
        builder.Property(p => p.AllowedMimeTypes).HasJsonbStringListConversion().IsRequired();

        builder.Property(p => p.MaxFileSizeMb).IsRequired().HasDefaultValue(10);
        builder.Property(p => p.DisplayOrder).IsRequired();
        builder.Property(p => p.ShowSample).IsRequired().HasDefaultValue(false);

        builder.HasOne(p => p.Template)
               .WithMany(t => t.PhotoSettings)
               .HasForeignKey(p => p.TemplateId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(p => new { p.TemplateId, p.GroupKey })
               .IsUnique()
               .HasFilter("\"IsDeleted\" = false");

        builder.ToTable(t =>
        {
            t.HasCheckConstraint(
                "CK_TemplatePhotoSettings_CountRange",
                "\"MinCount\" >= 0 AND \"MaxCount\" >= \"MinCount\"");
            t.HasCheckConstraint(
                "CK_TemplatePhotoSettings_FileSize",
                "\"MaxFileSizeMb\" BETWEEN 1 AND 100");
        });

        var ts = TemplateConfiguration.SeedTimestamp;
        var tid = TemplateConfiguration.SeedTemplateId;

        builder.HasData(
            new TemplatePhotoSetting
            {
                Id = new Guid("44444444-0001-0000-0000-000000000000"),
                TemplateId = tid,
                GroupKey = "vehicle_photos",
                Label = "Vehicle Photos",
                Instruction = "Please upload four photos of the vehicle from each corner.",
                MinCount = 4,
                MaxCount = 4,
                IsRequired = true,
                AllowedAngles = new List<string> { "front_left", "front_right", "rear_left", "rear_right" },
                SampleImageUrls = new List<string>(),
                MaxFileSizeMb = 10,
                AllowedMimeTypes = new List<string> { "image/jpeg", "image/png" },
                DisplayOrder = 1,
                CreatedAt = ts,
                IsDeleted = false,
                ShowSample = true
            },
            new TemplatePhotoSetting
            {
                Id = new Guid("44444444-0002-0000-0000-000000000000"),
                TemplateId = tid,
                GroupKey = "damage_photos",
                Label = "Damage Photos",
                Instruction = "Upload clear photos of the damage from multiple angles.",
                MinCount = 2,
                MaxCount = 10,
                IsRequired = true,
                AllowedAngles = new List<string> { "front", "side", "close_up" },
                SampleImageUrls = new List<string>(),
                MaxFileSizeMb = 10,
                AllowedMimeTypes = new List<string> { "image/jpeg", "image/png" },
                DisplayOrder = 2,
                CreatedAt = ts,
                IsDeleted = false,
                ShowSample = true
            },
            new TemplatePhotoSetting
            {
                Id = new Guid("44444444-0003-0000-0000-000000000000"),
                TemplateId = tid,
                GroupKey = "driver_license",
                Label = "Driver License",
                Instruction = "Upload the front and back of the driver license.",
                MinCount = 1,
                MaxCount = 2,
                IsRequired = true,
                AllowedAngles = new List<string> { "front", "back" },
                SampleImageUrls = new List<string>(),
                MaxFileSizeMb = 10,
                AllowedMimeTypes = new List<string> { "image/jpeg", "image/png" },
                DisplayOrder = 3,
                CreatedAt = ts,
                IsDeleted = false,
                ShowSample = false
            });
    }
}
