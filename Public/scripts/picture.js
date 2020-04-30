$('#picture')
  .on('change', function (e) {
    var reader = new FileReader();
    reader.onload = function (e) {
      $("#preview").attr('src', e.target.result);
    }
    reader.readAsDataURL(e.target.files[0]);
  });

function setBlogData() {
    var src = document.getElementById('preview').getAttribute('src')
    document.getElementById('pictureBase64').setAttribute('value', src)
}
