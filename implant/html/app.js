document.addEventListener('DOMContentLoaded', function() {
    const menu = document.getElementById('radial-menu');
    const closeButton = document.getElementById('close-button');

    window.addEventListener('message', function(event) {
        if (event.data.action === 'showMenu') {
            menu.style.display = 'flex';
        } else if (event.data.action === 'hideMenu') {
            menu.style.display = 'none';
        }
    });

    const menuItems = document.querySelectorAll('.menu-item');
    menuItems.forEach(item => {
        item.addEventListener('click', function() {
            const itemId = this.id;
            fetch(`https://${GetParentResourceName()}/selectItem`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json; charset=UTF-8',
                },
                body: JSON.stringify({
                    item: itemId
                })
            });
        });
    });

    closeButton.addEventListener('click', function() {
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            }
        });
    });
});

document.addEventListener('DOMContentLoaded', function() {
    window.addEventListener('message', function(event) {
        if (event.data.action === 'showMenu') {
            const elements = event.data.elements;
            const menuContainer = document.querySelector('.menu-container');
            menuContainer.innerHTML = ''; // Efface les boutons existants

            elements.forEach((element, index) => {
                const button = document.createElement('div');
                button.className = 'menu-item';
                button.id = `item${index + 1}`;
                button.textContent = element.label;
                button.dataset.value = element.value;

                button.addEventListener('click', function() {
                    fetch(`https://${GetParentResourceName()}/selectItem`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: JSON.stringify({
                            item: button.id
                        })
                    });
                });

                menuContainer.appendChild(button);
            });

            document.getElementById('radial-menu').style.display = 'flex';
        } else if (event.data.action === 'hideMenu') {
            document.getElementById('radial-menu').style.display = 'none';
        }
    });

    const closeButton = document.getElementById('close-button');
    closeButton.addEventListener('click', function() {
        fetch(`https://${GetParentResourceName()}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            }
        });
    });
});

elements.forEach((element, index) => {
    const button = document.createElement('div');
    button.className = 'menu-item';
    button.id = `item${index + 1}`;
    button.textContent = element.label;
    button.dataset.value = element.value;

    // Positionner les boutons en cercle
    const angle = (index / elements.length) * 2 * Math.PI;
    const x = Math.cos(angle) * 150; // Ajuster 150 pour augmenter ou diminuer la distance du centre
    const y = Math.sin(angle) * 150;
    button.style.transform = `translate(${x}px, ${y}px)`;

    button.addEventListener('click', function() {
        fetch(`https://${GetParentResourceName()}/selectItem`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                item: button.id
            })
        });
    });

    menuContainer.appendChild(button);
});
