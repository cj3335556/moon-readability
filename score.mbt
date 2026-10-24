///|
/// The components of a candidate's content score.
priv struct NodeScore {
  total : Int
  text_score : Int
  link_penalty : Int
  tag_score : Int
  class_score : Int
}

///|
/// A candidate node paired with its score.
priv struct ScoredNode {
  node : @html.Node
  score : NodeScore
}

///|
fn tag_weight(name : String) -> Int {
  let lowered = name.to_lower()
  if lowered == "article" || lowered == "main" {
    50
  } else if lowered == "section" {
    25
  } else if lowered == "div" {
    5
  } else if lowered == "p" {
    3
  } else if lowered == "nav" || lowered == "aside" || lowered == "footer" {
    -50
  } else if lowered == "form" {
    -40
  } else if lowered == "header" {
    -20
  } else {
    0
  }
}

///|
fn contains_any(text : String, needles : Array[String]) -> Bool {
  for needle in needles {
    if contains(text, needle) {
      return true
    }
  }
  false
}

///|
fn class_weight(node : @html.Node) -> Int {
  let mut score = 0
  let positive = ["article", "content", "post", "entry", "main", "body"]
  let negative = [
    "nav", "footer", "sidebar", "comment", "share", "ad", "menu", "promo",
  ]
  for token in node.class_tokens() {
    let lowered = token.to_lower()
    if contains_any(lowered, positive) {
      score += 30
    }
    if contains_any(lowered, negative) {
      score -= 30
    }
  }
  match node.id() {
    Some(id) => {
      let lowered = id.to_lower()
      if contains_any(lowered, positive) {
        score += 30
      }
      if contains_any(lowered, negative) {
        score -= 30
      }
    }
    None => ()
  }
  score
}

///|
fn score_node(node : @html.Node) -> NodeScore {
  let text_length = node.text_length()
  let text_score = if text_length > 1000 { 1000 } else { text_length }
  let link_penalty = if text_length == 0 {
    0
  } else {
    node.link_text_length() * 100 / text_length
  }
  let tag_score = tag_weight(node.name())
  let class_score = class_weight(node)
  {
    total: text_score - link_penalty + tag_score + class_score,
    text_score,
    link_penalty,
    tag_score,
    class_score,
  }
}

///|
fn candidate_nodes(doc : @html.Document) -> Array[@html.Node] {
  let result : Array[@html.Node] = []
  for selector in ["article", "main", "section", "div", "p"] {
    for node in doc.query(selector) {
      result.push(node)
    }
  }
  result
}

///|
fn score_document(doc : @html.Document) -> Array[ScoredNode] {
  let result : Array[ScoredNode] = []
  for node in candidate_nodes(doc) {
    result.push({ node, score: score_node(node) })
  }
  result
}

///|
fn is_better(candidate : ScoredNode, best : ScoredNode) -> Bool {
  if candidate.score.total != best.score.total {
    candidate.score.total > best.score.total
  } else if candidate.score.text_score != best.score.text_score {
    candidate.score.text_score > best.score.text_score
  } else if candidate.score.link_penalty != best.score.link_penalty {
    candidate.score.link_penalty < best.score.link_penalty
  } else if candidate.score.tag_score != best.score.tag_score {
    candidate.score.tag_score > best.score.tag_score
  } else {
    candidate.score.class_score > best.score.class_score
  }
}

///|
fn select_main_node(doc : @html.Document) -> @html.Node? {
  let scored = score_document(doc)
  let mut best : ScoredNode? = None
  for candidate in scored {
    match best {
      Some(current) => if is_better(candidate, current) {
        best = Some(candidate)
      }
      None => best = Some(candidate)
    }
  }
  match best {
    Some(value) => Some(value.node)
    None => None
  }
}

///|
fn negative_tag(name : String) -> Bool {
  contains_any(name.to_lower(), ["nav", "aside", "footer", "header", "form"])
}

///|
fn negative_class(node : @html.Node) -> Bool {
  let negative = ["nav", "footer", "sidebar", "comment", "share", "ad", "menu", "promo"]
  for token in node.class_tokens() {
    if contains_any(token.to_lower(), negative) {
      return true
    }
  }
  false
}

///|
fn shares_class(a : @html.Node, b : @html.Node) -> Bool {
  for left in a.class_tokens() {
    for right in b.class_tokens() {
      if left == right {
        return true
      }
    }
  }
  false
}

///|
fn should_merge(node : @html.Node, selected : @html.Node) -> Bool {
  if node.same(selected) {
    return true
  }
  if !node.is_element() {
    return false
  }
  if negative_tag(node.name()) || negative_class(node) {
    return false
  }
  if node.link_density() > 0.5 {
    return false
  }
  if node.text_length() < 80 {
    return false
  }
  shares_class(node, selected) ||
  node.text_length() >= 200 ||
  node.name() == selected.name()
}

///|
fn select_content_nodes(doc : @html.Document) -> Array[@html.Node] {
  match select_main_node(doc) {
    Some(selected) => {
      let siblings = selected.siblings()
      if siblings.length() == 0 {
        return [selected]
      }
      let result : Array[@html.Node] = []
      for sibling in siblings {
        if should_merge(sibling, selected) {
          result.push(sibling)
        }
      }
      if result.length() == 0 {
        result.push(selected)
      }
      result
    }
    None => []
  }
}
