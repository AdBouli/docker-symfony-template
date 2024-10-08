// @file bootstrap_controller.js
// @author Adrien Boulineau <adbouli@vivaldi.net>

import { Controller } from '@hotwired/stimulus';
import { Popover } from 'bootstrap';

export default class extends Controller {
    connect() {
        [...this.element.querySelectorAll('[data-bs-toggle="popover"]')].map(popover => new Popover(popover));
    }
}
