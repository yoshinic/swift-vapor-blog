function initQuill() {
  const toolbarOptions = [
    [{ 'font': [] }],
    [{ 'size': [] }],
    ['bold', 'italic', 'underline', 'strike'],
    [{ 'color': [] }, { 'background': [] }],
    [{ 'header': [1, 2, 3, 4, 5, 6, false] }],

    ['link'],

    ['image', 'video'],

    ['blockquote', 'code-block'],
    [{ 'list': 'ordered' }, { 'list': 'bullet' }],

    [{ 'align': [] }],
    [{ 'indent': '-1' }, { 'indent': '+1' }],
    [{ 'direction': 'rtl' }],

    [{ 'script': 'sub' }, { 'script': 'super' }],
  ];

  return new Quill(
    '#editor',
    {
      modules: {
        syntax: true,
        toolbar: toolbarOptions
      },
      placeholder: '何でも書いて下さい！',
      theme: 'snow'
    }
  );
}

function unescapeHTML(str) {
  const div = document.createElement("div");
  div.innerHTML = str.replace(/</g,"&lt;")
                     .replace(/>/g,"&gt;")
                     .replace(/ /g, "&nbsp;")
                     .replace(/\r/g, "&#13;")
                     .replace(/\n/g, "&#10;");
  return div.textContent || div.innerText;
}

function getUpdatedContentsData() {
  const contents = quill.getContents()
  const jsonData = JSON.stringify(contents)
  return jsonData
}

function getSelectedTags() {
  let a = []
  const e = document.getElementsByClassName('select2-selection__choice');
  for (const o of e) {
    a.push(o.getAttribute('title'))
  }
  return a.join(',')
}

// formdata イベントを使用しない form submit 関数
!function(){
	FormData.prototype.submit = async function(form_attribute = {}){
		const form = document.createElement("form")
		Object.entries(form_attribute).forEach(([k, v]) => {
			form.setAttribute(k, v)
		})
		form.hidden = true
		
		const inputs = await Promise.all([...this.entries()].map(([k, v]) => new Promise((ok, fail) => {
			const input = document.createElement("input")
			input.name = k
			
			if(typeof v === "string"){
				input.value = v
				ok(input)
			}else if(v instanceof File){
				const file = v
				if(file.name === "" && file.type === ""){
					input.value = ""
					ok(input)
					return
				}
				const reader = new FileReader()
				reader.onload = eve => {
					input.value = JSON.stringify({
						lastModified: file.lastModified,
						name: file.name,
						size: file.size,
						type: file.type,
						data: reader.result
					})
					ok(input)
				}
				reader.onerror = eve => {
					fail()
				}
				reader.readAsDataURL(file)
			}
		})))
		
		form.append(...inputs)
		document.body.append(form)
		form.submit()
		form.remove()
	}
}()

// formdata イベントを使用しない
let pictureBlobData = null;
function submitBlogData(editURI) {
  const fd = new FormData();

  let comment;
  const _comment = document.getElementById('comment');
  if (_comment == null) {
    comment = null
  } else {
    comment = _comment.value;
  }
  const picture = pictureBlobData;
  const updatingPicture = document.getElementById('updatingPicture').value;
  const title = document.getElementById('title').value;
  const contents = getUpdatedContentsData();
  const tags = getSelectedTags();

  let csrfToken;
  const _csrfToken = document.getElementById('csrfToken');
  if (_csrfToken == null) {
    csrfToken = null
  } else {
    csrfToken = document.getElementById('csrfToken').value;
  }

  fd.append('comment', comment)
  if (picture != undefined || picture != null) { fd.append('picture', picture) }
  fd.append('updatingPicture', updatingPicture)
  fd.append('title', title)
  fd.append('contents', contents)
  fd.append('tags', tags)
  fd.append('csrfToken', csrfToken)

  let uri;
  if (editURI == "") {
    uri = "/blogs/create"
  } else {
    uri = "/blogs/" + editURI + "/edit"
  }
  
  fd.submit({
    method: "POST",
    action: uri,
    enctype: "multipart/form-data",
    hidden: true
  })
}

// ブログを編集するとき、既に保存してあるブログデータをサーバーから読み込む
function readContentsData(uri) {
  fetch(uri, {
    method: 'GET'
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`${response.status} ${response.statusText}`);
      }
      // レスポンスが JSON 形式で返っていることを想定
      return response.arrayBuffer();
    })
    .then((data) => {
      const u8arr = new Uint8Array(data);
      const s = new TextDecoder().decode(u8arr);
      const x = unescapeHTML(s).replace(/\n/g, "\\n")
      const j = JSON.parse(x);
      quill.setContents(j);
    })
    .catch((reason) => {
      // エラー処理
      console.log('** fetch: catch');
      console.log(reason);
    });
}

function addPictureHandler() {
  // 画像を選択した時表示する
  window.addEventListener('DOMContentLoaded', function () {
    document.querySelector("#picture").addEventListener('change', function (e) {
      const reader = new FileReader();
      reader.onload = function (e) {
        myCroppie.bind({ url: e.target.result });
      }
      reader.readAsDataURL(e.target.files[0]);
    }, true);
  });

  // 画像の選択・トリミング決定
  window.addEventListener('DOMContentLoaded', function () {
    document.querySelector("#pictureButton").addEventListener('click', function (e) {
      myCroppie.result('base64', 'viewport', 'png', 1, false).then(function (base64) {
        document.getElementById('preview').setAttribute('src', base64);
      });
      myCroppie.result('blob', 'viewport', 'png', 1, false).then(function (blob) {
        pictureBlobData = blob
      });
      document.getElementById('updatingPicture').setAttribute('value', "true");
    
      // Modal を閉じる
      closeModals();
    }, true);
  });
}

// ブログデータ送信ボタンイベント追加
function addSubmitBlogDataHandler(editURI) {
  window.addEventListener('DOMContentLoaded', function () {
    document.querySelector("\#submitButton").addEventListener('click', function (e) {
      submitBlogData(editURI);
    }, true);
  });
}

// 画面表示時に読み込む処理セット
addPictureHandler();
const quill = initQuill();
