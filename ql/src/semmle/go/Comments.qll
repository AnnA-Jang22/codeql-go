/**
 * Provides classes for working with code comments.
 */

import go

/**
 * A code comment.
 */
class Comment extends @comment, AstNode {
  /**
   * Gets the text of this comment, not including delimiters.
   */
  string getText() { comments(this, _, _, _, result) }

  /**
   * Gets the comment group to which this comment belongs.
   */
  CommentGroup getGroup() { this = result.getAComment() }

  override string toString() { result = "comment" }
}

/**
 * A comment group, that is, a sequence of comments without any intervening tokens or
 * empty lines.
 */
class CommentGroup extends @comment_group, AstNode {
  /** Gets the `i`th comment in this group (0-based indexing). */
  Comment getComment(int i) { comments(result, _, this, i, _) }

  /** Gets a comment in this group. */
  Comment getAComment() { result = getComment(_) }

  /** Gets the number of comments in this group. */
  int getNumComment() { result = count(getAComment()) }

  override string toString() { result = "comment group" }
}

/**
 * A program element to which a documentation comment group may be attached.
 */
class Documentable extends AstNode, @documentable {
  /** Gets the documentation comment group attached to this element, if any. */
  DocComment getDocumentation() { this = result.getDocumentedElement() }
}

/**
 * A comment group that is attached to a program element as documentation.
 */
class DocComment extends CommentGroup {
  Documentable node;

  DocComment() { doc_comments(node, this) }

  /** Gets the program element documented by this comment group. */
  Documentable getDocumentedElement() { result = node }
}

/**
 * A single-line comment starting with `//`.
 */
class SlashSlashComment extends @slashslashcomment, Comment { }

/**
 * A block comment starting with `/*` and ending with <code>*&#47;</code>.
 */
class SlashStarComment extends @slashstarcomment, Comment { }

/**
 * A single-line comment starting with `//`.
 */
class LineComment = SlashSlashComment;

/**
 * A block comment starting with `/*` and ending with <code>*&#47;</code>.
 */
class BlockComment = SlashStarComment;

/** Holds if `c` starts at `line`, `col` in `f`, and precedes the package declaration. */
private predicate isInitialComment(Comment c, File f, int line, int col) {
  c.hasLocationInfo(f.getAbsolutePath(), line, col, _, _) and
  line < f.getPackageNameExpr().getLocation().getStartLine()
}

/** Gets the `i`th initial comment in `f` (0-based). */
private Comment getInitialComment(File f, int i) {
  result =
    rank[i + 1](Comment c, int line, int col |
      isInitialComment(c, f, line, col)
    |
      c order by line, col
    )
}

/**
 * A build constraint comment of the form `// +build ...`.
 */
class BuildConstraintComment extends LineComment {
  BuildConstraintComment() {
    // a line comment preceding the package declaration, itself only preceded by
    // line comments
    exists(File f, int i |
      this = getInitialComment(f, i) and
      not getInitialComment(f, [0 .. i - 1]) instanceof BlockComment
    ) and
    // comment text starts with `+build`
    getText().regexpMatch("\\s*\\+build.*")
  }
}
