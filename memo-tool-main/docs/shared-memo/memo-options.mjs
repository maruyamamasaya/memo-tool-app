export function memoOptions(data={}) {return {usage:data.usage==="temporary"?"temporary":"saved",confidential:data.confidential===true,contentKind:["prompt","command","code"].includes(data.contentKind)?data.contentKind:"note"}}
export function parseRawMemo(title,body,tags="") {return {title:title.trim().slice(0,120),body,tags:[...new Set(tags.split(/[\s,、]+/).map(t=>t.replace(/^#/,"")).filter(Boolean))].slice(0,20)}}
export function matchesUsage(memo,view) {return view==="temporary"||view==="saved"?memo.usage===view:view==="pinned"?memo.pinned:view==="confidential"?memo.confidential:true}
