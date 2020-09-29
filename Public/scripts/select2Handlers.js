$.ajax( 
  {
    url: "/api/tags/", 
    type: "GET",
    contentType: "application/json; charset=utf-8"
  }
)
.then(
  function (response) {
    var dataToReturn = [];
    for (var i = 0; i < response.length; i++) {
      var tagToTransform = response[i];
      var newTag = {
        id: tagToTransform["name"],
        text: tagToTransform["name"]
      };
      dataToReturn.push(newTag);
    }
    $("#selects").select2(
      {
        placeholder: "タグを入力して下さい。",
        tags: true,
        tokenSeparators: [','],
        data: dataToReturn,
        language: "ja",
        width: '100%',
        dropdownCssClass: 'selects-dropdown'
      }
    );
  }
);
