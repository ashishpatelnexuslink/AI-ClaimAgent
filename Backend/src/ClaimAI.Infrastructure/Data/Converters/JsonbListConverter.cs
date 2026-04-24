using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace ClaimAI.Infrastructure.Data.Converters;

/// <summary>
/// Helpers that wire a <c>List&lt;T&gt;</c> property to a PostgreSQL <c>jsonb</c>
/// column via a <see cref="ValueConverter{TModel,TProvider}"/> and a
/// <see cref="ValueComparer{T}"/> (required so EF change-tracking detects
/// mutations on the list in place, not just reference swaps).
/// </summary>
public static class JsonbListConverter
{
    private static readonly JsonSerializerOptions SerializerOptions = new();

    /// <summary>
    /// Apply JSONB conversion for a property typed <c>List&lt;string&gt;</c>.
    /// </summary>
    public static PropertyBuilder<List<string>> HasJsonbStringListConversion(
        this PropertyBuilder<List<string>> builder)
    {
        builder.HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v, SerializerOptions),
                   v => JsonSerializer.Deserialize<List<string>>(v, SerializerOptions) ?? new List<string>());

        builder.Metadata.SetValueComparer(new ValueComparer<List<string>>(
            (a, b) => (a == null && b == null) || (a != null && b != null && a.SequenceEqual(b)),
            c => c == null ? 0 : c.Aggregate(0, (acc, v) => HashCode.Combine(acc, v.GetHashCode())),
            c => c == null ? new List<string>() : c.ToList()));

        return builder;
    }

    /// <summary>
    /// Apply JSONB conversion for a property typed <c>List&lt;TEnum&gt;</c> where
    /// <typeparamref name="TEnum"/> is a CLR enum. Values are serialized as
    /// their name (matching the <c>HasConversion&lt;string&gt;()</c> convention
    /// used for scalar enum columns in this codebase).
    /// </summary>
    public static PropertyBuilder<List<TEnum>> HasJsonbEnumListConversion<TEnum>(
        this PropertyBuilder<List<TEnum>> builder)
        where TEnum : struct, Enum
    {
        builder.HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v.Select(e => e.ToString()).ToList(), SerializerOptions),
                   v => DeserializeEnumList<TEnum>(v));

        builder.Metadata.SetValueComparer(new ValueComparer<List<TEnum>>(
            (a, b) => (a == null && b == null) || (a != null && b != null && a.SequenceEqual(b)),
            c => c == null ? 0 : c.Aggregate(0, (acc, v) => HashCode.Combine(acc, v.GetHashCode())),
            c => c == null ? new List<TEnum>() : c.ToList()));

        return builder;
    }

    private static List<TEnum> DeserializeEnumList<TEnum>(string json)
        where TEnum : struct, Enum
    {
        var names = JsonSerializer.Deserialize<List<string>>(json, SerializerOptions) ?? new List<string>();
        var result = new List<TEnum>(names.Count);
        foreach (var name in names)
        {
            if (Enum.TryParse<TEnum>(name, ignoreCase: false, out var parsed))
                result.Add(parsed);
        }
        return result;
    }
}
