import {test} from 'node:test';
import assert from 'node:assert/strict';
import {memoOptions,parseRawMemo,matchesUsage} from '../docs/shared-memo/memo-options.mjs';
test('legacy records default to saved, public, note without migration',()=>assert.deepEqual(memoOptions({}),{usage:'saved',confidential:false,contentKind:'note'}));
test('independent flags and malformed defaults',()=>{assert.deepEqual(memoOptions({usage:'temporary',confidential:true,contentKind:'command'}),{usage:'temporary',confidential:true,contentKind:'command'});assert.equal(memoOptions({confidential:'true',contentKind:'invalid'}).confidential,false)});
test('raw prompt/command preserves tabs, CRLF, trailing newline and hash',()=>{const body='  printf "hello"\r\n\t# shell comment\n\n';assert.equal(parseRawMemo('',body).body,body);assert.equal(parseRawMemo('',body).title,'')});
test('filtering composes usage and flags, unknown/all stays compatible',()=>{const m={...memoOptions({usage:'temporary',confidential:true}),pinned:true};assert.ok(matchesUsage(m,'temporary'));assert.ok(!matchesUsage(m,'saved'));assert.ok(matchesUsage(m,'pinned'));assert.ok(matchesUsage(m,'confidential'));assert.ok(matchesUsage(m,'all'))});
