using AutoMapper;
using ClaimAI.Application.DTOs.Templates;
using ClaimAI.Domain.Entities.Templates;

namespace ClaimAI.Application.Mappings;

public class TemplateMappingProfile : Profile
{
    public TemplateMappingProfile()
    {
        // Entity -> read DTOs
        CreateMap<Template, TemplateListItemDto>();
        CreateMap<Template, TemplateDetailDto>();
        CreateMap<TemplateIdentityField, IdentityFieldDto>();
        CreateMap<TemplateFieldGroupRule, GroupRuleDto>();
        CreateMap<TemplatePhotoSetting, PhotoSettingDto>();
        CreateMap<TemplateDocumentSetting, DocumentSettingDto>();

        // Create DTOs -> entities. TemplateId is stamped by EF via the parent
        // navigation; we ignore it on mapping so the nested-tree create works.
        CreateMap<CreateIdentityFieldDto, TemplateIdentityField>()
            .ForMember(d => d.Id, o => o.Ignore())
            .ForMember(d => d.TemplateId, o => o.Ignore())
            .ForMember(d => d.Template, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedBy, o => o.Ignore())
            .ForMember(d => d.IsDeleted, o => o.Ignore());

        CreateMap<CreateGroupRuleDto, TemplateFieldGroupRule>()
            .ForMember(d => d.Id, o => o.Ignore())
            .ForMember(d => d.TemplateId, o => o.Ignore())
            .ForMember(d => d.Template, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedBy, o => o.Ignore())
            .ForMember(d => d.IsDeleted, o => o.Ignore());

        CreateMap<CreatePhotoSettingDto, TemplatePhotoSetting>()
            .ForMember(d => d.Id, o => o.Ignore())
            .ForMember(d => d.TemplateId, o => o.Ignore())
            .ForMember(d => d.Template, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedBy, o => o.Ignore())
            .ForMember(d => d.IsDeleted, o => o.Ignore());

        CreateMap<CreateDocumentSettingDto, TemplateDocumentSetting>()
            .ForMember(d => d.Id, o => o.Ignore())
            .ForMember(d => d.TemplateId, o => o.Ignore())
            .ForMember(d => d.Template, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedBy, o => o.Ignore())
            .ForMember(d => d.IsDeleted, o => o.Ignore());

        CreateMap<CreateTemplateDto, Template>()
            .ForMember(d => d.Id, o => o.Ignore())
            .ForMember(d => d.Version, o => o.Ignore())
            .ForMember(d => d.Status, o => o.Ignore())
            .ForMember(d => d.CreatedAt, o => o.Ignore())
            .ForMember(d => d.UpdatedAt, o => o.Ignore())
            .ForMember(d => d.CreatedBy, o => o.Ignore())
            .ForMember(d => d.UpdatedBy, o => o.Ignore())
            .ForMember(d => d.IsDeleted, o => o.Ignore());
    }
}
