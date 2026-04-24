using ClaimAI.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ClaimAI.Infrastructure.Data.Configurations;

public class ConversationConfiguration : IEntityTypeConfiguration<Conversation>
{
    public void Configure(EntityTypeBuilder<Conversation> builder)
    {
        builder.Property(c => c.UserId).IsRequired().HasMaxLength(450);
        builder.Property(c => c.Title).HasMaxLength(200);

        builder.HasOne(c => c.User)
               .WithMany()
               .HasForeignKey(c => c.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.Claim)
               .WithMany()
               .HasForeignKey(c => c.ClaimId)
               .OnDelete(DeleteBehavior.SetNull);

        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => c.ClaimId);
    }
}
