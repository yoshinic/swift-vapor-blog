const croppieView = document.getElementById('croppie-view');

const myCroppie = new Croppie(croppieView, {
    viewport: {
        width: 400,
        height: 300,
        type: 'square'
    //        type: 'circle'
    },
    boundary: {
        width: 500,
        height: 400
    },
    enableResize: true
});
