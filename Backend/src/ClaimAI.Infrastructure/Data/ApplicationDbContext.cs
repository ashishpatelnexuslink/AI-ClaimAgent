using System.Linq.Expressions;
using ClaimAI.Domain.Entities;
using ClaimAI.Domain.Entities.Templates;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace ClaimAI.Infrastructure.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public DbSet<Claim> Claims => Set<Claim>();
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();
    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<ClaimDocument> ClaimDocuments => Set<ClaimDocument>();

    public DbSet<Template> Templates => Set<Template>();
    public DbSet<TemplateIdentityField> TemplateIdentityFields => Set<TemplateIdentityField>();
    public DbSet<TemplateFieldGroupRule> TemplateFieldGroupRules => Set<TemplateFieldGroupRule>();
    public DbSet<TemplatePhotoSetting> TemplatePhotoSettings => Set<TemplatePhotoSetting>();
    public DbSet<TemplateDocumentSetting> TemplateDocumentSettings => Set<TemplateDocumentSetting>();

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);

        // Apply soft delete global query filter to all BaseEntity-derived entities
        foreach (var entityType in builder.Model.GetEntityTypes())
        {
            if (typeof(BaseEntity).IsAssignableFrom(entityType.ClrType))
            {
                var parameter = Expression.Parameter(entityType.ClrType, "e");
                var property = Expression.Property(parameter, nameof(BaseEntity.IsDeleted));
                var falseConstant = Expression.Constant(false);
                var condition = Expression.Equal(property, falseConstant);
                var lambda = Expression.Lambda(condition, parameter);

                builder.Entity(entityType.ClrType).HasQueryFilter(lambda);
            }
        }
    }
}
