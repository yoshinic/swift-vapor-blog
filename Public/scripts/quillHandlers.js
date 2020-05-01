var quill;
function initQuill(readonly) {
  hljs.initHighlightingOnLoad();

  if (readonly) {
    quill = new Quill(
      '#editor', 
      {
        modules: {
          syntax: true,
          toolbar: null
        },
        readOnly: true,
        theme: 'snow'
      }
    );
  } else {
    var toolbarOptions = [
      [{ 'font': [] }],
      [{ 'size': [] }],
      ['bold', 'italic', 'underline', 'strike'],      
      [{ 'color': [] }, { 'background': [] }],        
      [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
      
      ['image', 'video'],
      
      ['blockquote', 'code-block'],
      [{ 'list': 'ordered'}, { 'list': 'bullet' }],
      
      [{ 'align': [] }],
      [{ 'indent': '-1'}, { 'indent': '+1' }],
      [{ 'direction': 'rtl' }],
      
      [{ 'script': 'sub'}, { 'script': 'super' }],
    ];

    quill = new Quill(
      '#editor', 
      {
        modules: {
          syntax: true,
          toolbar: toolbarOptions
        },
        placeholder: '本文を入力',
        theme: 'snow'
      }
    );
  }
}

function setBlogData() {
  var src = document.getElementById('preview').getAttribute('src')
  document.getElementById('pictureBase64').setAttribute('value', src)
    
  var contents = quill.getContents()
  var jsonData = JSON.stringify(contents["ops"])
  document.getElementById('contents').setAttribute('value', jsonData)
}

function unescapeHTML(str) {
  var div = document.createElement("div");
  div.innerHTML = str.replace(/</g,"&lt;")
                     .replace(/>/g,"&gt;")
                     .replace(/ /g, "&nbsp;")
                     .replace(/\r/g, "&#13;")
                     .replace(/\n/g, "&#10;");
  return div.textContent || div.innerText;
}

function readBlogData(str) {
  var x = unescapeHTML(str).replace(/\n/g, "\\n")
  var j = JSON.parse(x);
  quill.setContents(j);
}

function setQuillData(str) {
  readBlogData(str, quill)
  var html = document.getElementsByClassName('ql-editor')[0].innerHTML
  document.getElementById('view').innerHTML = html
}
