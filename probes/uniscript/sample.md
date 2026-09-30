<:alpha> <:beta> <:gamma>: this file starts with the uniscript marker, so MarkdownPreview converts uniscript in its prose.

# Uniscript in <:fracture M>arkdown

## Unknown entities stay visible

Neither <:nosuchthing> nor \:nosuchthing is an entity.

## Unsupported characters are kept and marked

No Greek c: <:greek c>, red cannot color <:red 𓀀>, no beside group of <:beside a b>.

## Code is left alone

Inline `<:alpha> \:infinity` stays as written, and so do code blocks:

```
<:alpha> \:infinity <:fracture A>
```

    <:beta> in an indented block

## Wiki examples

- `\:infinity` → \:infinity
- `<:fracture A>` → <:fracture A>
- `<:fracture A b c >` → <:fracture A b c >
- `<:fracture> A b c <:>` → <:fracture> A b c <:>
- `<:greek> a b g d <:/greek>` → <:greek> a b g d <:/greek>
- `<:greek> athos <:/greek> <:greek eta Omega lambda>` → <:greek> athos <:/greek> <:greek eta Omega lambda>
- `x<:upper a> X<:upper A>` → x<:upper a> X<:upper A>
- `<:ligature ae>` → <:ligature ae>
- `<:red circle> <:brown heart>` → <:red circle> <:brown heart>
- `<:reverseInPlace e>` → <:reverseInPlace e>
- `<:iconic ⚠>` → <:iconic ⚠>
- `<:mirror red A>` → <:mirror red A>
- `<:forall> x <:in> <:double R>` → <:forall> x <:in> <:double R>
- `<:above 𓀀 𓁐> <:beside 犭 句>` → <:above 𓀀 𓁐> <:beside 犭 句>
- `a literal <<::> marker` → a literal <<::> marker

**Bold <:alpha>**, *italic <:Omega>* and a [link to <:infinity>](https://example.com).

| uniscript | Unicode |
|---|---|
| `<:double R>` | <:double R> |
| `<:greek small letter alpha>` | <:greek small letter alpha> |
