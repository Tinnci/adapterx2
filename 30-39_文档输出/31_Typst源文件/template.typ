// =============================================================================
// AdapterX2 Typst 文档模板
// =============================================================================
// 文件编号: 31.00
// 描述: 定义文档样式、颜色、布局等
// =============================================================================

// -----------------------------------------------------------------------------
// 颜色定义
// -----------------------------------------------------------------------------

#let color-primary = rgb("#1a56db")      // 主色调 - 蓝色
#let color-secondary = rgb("#6b7280")    // 次要色 - 灰色
#let color-accent = rgb("#059669")       // 强调色 - 绿色
#let color-warning = rgb("#dc2626")      // 警告色 - 红色
#let color-info = rgb("#0891b2")         // 信息色 - 青色

#let color-bg-warning = rgb("#fef2f2")   // 警告背景
#let color-bg-info = rgb("#ecfeff")      // 信息背景

// -----------------------------------------------------------------------------
// 警告框和信息框
// -----------------------------------------------------------------------------

#let warning-box(body) = {
  block(
    width: 100%,
    fill: color-bg-warning,
    stroke: (left: 3pt + color-warning),
    inset: 12pt,
    radius: (right: 4pt),
    body
  )
}

#let info-box(body) = {
  block(
    width: 100%,
    fill: color-bg-info,
    stroke: (left: 3pt + color-info),
    inset: 12pt,
    radius: (right: 4pt),
    body
  )
}

// -----------------------------------------------------------------------------
// 主项目模板
// -----------------------------------------------------------------------------

#let project(
  title: none,
  subtitle: none,
  authors: (),
  date: none,
  version: none,
  body,
) = {
  // 文档元数据
  set document(
    author: authors.map(a => a.name),
    title: title,
  )
  
  // 页面设置
  set page(
    paper: "a4",
    margin: (
      top: 2.5cm,
      bottom: 2.5cm,
      left: 2.5cm,
      right: 2cm,
    ),
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 9pt, fill: color-secondary)
        grid(
          columns: (1fr, 1fr),
          align: (left, right),
          [AdapterX2 设计文档],
          [#version],
        )
        line(length: 100%, stroke: 0.5pt + color-secondary)
      }
    },
    footer: context {
      set text(size: 9pt, fill: color-secondary)
      line(length: 100%, stroke: 0.5pt + color-secondary)
      v(4pt)
      grid(
        columns: (1fr, 1fr),
        align: (left, right),
        [#date],
        [第 #counter(page).display() 页],
      )
    },
  )
  
  // 字体设置
  set text(
    font: ("Noto Sans CJK SC", "Noto Sans", "Source Han Sans SC"),
    size: 10.5pt,
    lang: "zh",
  )
  
  // 段落设置
  set par(
    justify: true,
    leading: 0.8em,
    first-line-indent: 2em,
  )
  
  // 标题设置
  set heading(numbering: "1.1")
  
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    set text(size: 18pt, weight: "bold", fill: color-primary)
    v(0.5em)
    block(it)
    v(0.5em)
  }
  
  show heading.where(level: 2): it => {
    set text(size: 14pt, weight: "bold", fill: color-primary)
    v(0.3em)
    block(it)
    v(0.3em)
  }
  
  show heading.where(level: 3): it => {
    set text(size: 12pt, weight: "bold")
    v(0.2em)
    block(it)
    v(0.2em)
  }
  
  // 代码块设置
  show raw.where(block: true): it => {
    set text(font: ("JetBrains Mono", "Fira Code", "Source Code Pro"), size: 9pt)
    block(
      width: 100%,
      fill: luma(245),
      stroke: 0.5pt + luma(200),
      inset: 10pt,
      radius: 4pt,
      it
    )
  }
  
  show raw.where(block: false): it => {
    set text(font: ("JetBrains Mono", "Fira Code", "Source Code Pro"))
    box(
      fill: luma(240),
      inset: (x: 3pt, y: 0pt),
      outset: (y: 3pt),
      radius: 2pt,
      it
    )
  }
  
  // 表格设置
  show figure.where(kind: table): set figure.caption(position: top)
  
  // 链接设置
  show link: it => {
    set text(fill: color-primary)
    underline(it)
  }
  
  // -----------------------------------------------------------------------------
  // 封面页
  // -----------------------------------------------------------------------------
  
  v(3cm)
  
  align(center)[
    #block(
      width: 100%,
      stroke: (bottom: 2pt + color-primary),
      inset: (bottom: 20pt),
      [
        #text(size: 28pt, weight: "bold", fill: color-primary)[#title]
        
        #if subtitle != none {
          v(0.5em)
          text(size: 16pt, fill: color-secondary)[#subtitle]
        }
      ]
    )
  ]
  
  v(2cm)
  
  align(center)[
    #if authors.len() > 0 {
      for author in authors {
        block[
          #text(size: 12pt)[#author.name]
          #if author.affiliation != "" {
            linebreak()
            text(size: 10pt, fill: color-secondary)[#author.affiliation]
          }
        ]
      }
    }
    
    #v(1cm)
    
    #text(size: 11pt, fill: color-secondary)[
      #version
      #h(2em)
      #date
    ]
  ]
  
  v(3cm)
  
  align(center)[
    #block(
      width: 80%,
      fill: color-bg-warning,
      stroke: color-warning,
      inset: 15pt,
      radius: 4pt,
      [
        #text(weight: "bold", fill: color-warning)[⚠️ 重要安全警告]
        
        #v(0.5em)
        
        本文档涉及的两款转接板具有不同的电气特性。
        
        *错误使用可能导致设备永久性损坏！*
        
        请在操作前仔细阅读全部内容。
      ]
    )
  ]
  
  pagebreak()
  
  // -----------------------------------------------------------------------------
  // 正文
  // -----------------------------------------------------------------------------
  
  body
}
