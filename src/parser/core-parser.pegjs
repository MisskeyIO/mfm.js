{
	const {
		createTree,
		mergeText
	} = require('./parser-utils');

	function applyParser(input, rule) {
		let parseFunc = peg$parse;
		return parseFunc(input, rule ? { startRule : rule } : { });
	}
}

root
	= ts:all*
{
	return mergeText(ts);
}

all
	= block / inline

// plain
// 	=

block
	= title
	/ quote
	/ search
	/ blockCode

inline
	= big
	/ c:. { return createTree('text', { text: c }); }


// block: title

title
	= titleA / titleB

titleA
	= "【" content:(!("】" ENDLINE) i:inline { return i; })+ "】" ENDLINE
{
	return createTree('title', { }, content);
}

titleB
	= "[" content:(!("]" ENDLINE) i:inline { return i; })+ "]" ENDLINE
{
	return createTree('title', { }, content);
}


// block: quote

quote
	= lines:quote_line+
{
	const children = applyParser(lines.join('\n'), 'root');
	return createTree('quote', { }, children);
}

quote_line
	= ">" _? content:$(CHAR+) ENDLINE { return content; }


// block: search

search
	= q:search_query sp:[ 　\t] key:search_keyToken ENDLINE
{
	return createTree('search', {
		query: q,
		content: [ q, sp, key ].join('')
	});
}

search_query
	= head:CHAR tail:(!([ 　\t] search_keyToken ENDLINE) c:CHAR { return c; })*
{
	return head + tail.join('');
}

search_keyToken
	= "検索" / "search"i


// block: blockCode

blockCode
	= "```" NEWLINE lines: (!("```" ENDLINE) line:blockCode_line NEWLINE { return line; } )* "```" ENDLINE { return lines; }

blockCode_line
	= (!"```" (block / inline))+


// inline: big

big
	= "***" content:(!"***" i:inline { return i; })+ "***"
{
	return createTree('big', { }, content);
}


// inline: bold

bold = bold_A / bold_B

bold_A
	= "**" content:(!"**" i:inline { return i; })+ "**"
{
	return createTree('bold', { }, content);
}

bold_B
	= "__" content:(!"__" i:inline { return i; })+ "__"
{
	return createTree('bold', { }, content);
}


// Core rules

CHAR
	= !NEWLINE c:. { return c; }

ENDLINE
	= NEWLINE / EOF

NEWLINE
	= "\r\n" / [\r\n]

EOF
	= !.

_ "whitespace"
	= [ \t]
