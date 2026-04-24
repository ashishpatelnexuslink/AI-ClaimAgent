using ClaimAI.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class ConversationMessageConfiguration : IEntityTypeConfiguration<ConversationMessage>
{
    public void Configure(EntityTypeBuilder<ConversationMessage> builder)
    {
        builder.Property(m => m.ConversationId).IsRequired();

        builder.Property(m => m.Role)
               .IsRequired()
               .HasConversion<string>()
               .HasMaxLength(20);

        builder.Property(m => m.Content).IsRequired();

        builder.Property(m => m.Metadata)
               .HasColumnType("jsonb");

        builder.HasOne(m => m.Conversation)
               .WithMany(c => c.Messages)
               .HasForeignKey(m => m.ConversationId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(m => new { m.ConversationId, m.CreatedAt });
    }
}
