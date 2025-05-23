from PyQt5 import QtWidgets, QtGui
from src.ui import Ui_MainWindow # type: ignore
from src.processing import find_diameter, find_contours, save_contours_as_dxf, select_image, import_to_openscad, exit_application, clear_canvas, create_main_window, display_image_on_canvas # type: ignore
import cv2
import traceback
from PIL import Image
import threading
import os
from datetime import datetime
#from src.undistort_image import load_calibration_data, undistort_image  # Import necessary functions

def create_main_window():
    MainWindow = QtWidgets.QMainWindow()
    ui = Ui_MainWindow()
    ui.setupUi(MainWindow)
    
    canvas = ui.canvas
    canvas.setScene(QtWidgets.QGraphicsScene())
    
    ui.console_text.setText("Input Project Name then Load Image")  # Set default console text
    
    return (MainWindow, ui, canvas, ui.load_button, ui.process_button, ui.import_button, 
            ui.exit_button, ui.threshold_entry, ui.offset_entry, ui.token_entry, 
            ui.resolution_entry, ui.console_text)

def main():
    CALIBRATION_FILE = '/src/calibration_data.pkl'
    global threshold_entry, offset_entry, token_entry, resolution_entry, input_image_path, file_name, console_text, image
    app = QtWidgets.QApplication([])
    window, ui, canvas, load_button, process_button, import_button, exit_button, threshold_entry, offset_entry, token_entry, resolution_entry, console_text = create_main_window()

    def toggle_load_button():
        load_button.setEnabled(bool(ui.lineEdit.text()))  # Enable if lineEdit has text

    ui.lineEdit.textChanged.connect(toggle_load_button)  # Connect textChanged signal
    toggle_load_button()  # Initial check to set the correct state of load_button

    def load_image():
        global input_image_path, file_name, image
        try:
            clear_canvas(canvas)
            input_image_path, file_name = select_image(console_text)
            if not input_image_path:
                print("No image selected. Exiting.")  # Changed from console_text
                return
            print(f"Loaded image: {input_image_path}")  # Changed from console_text
            image = cv2.imread(input_image_path)
            if image is None:
                print("Failed to load image.")  # Changed from console_text
                return
            
            display_image_on_canvas(image, canvas, 1, "Original")
            
            folder_name = ui.lineEdit.text().strip()  # Get folder name from lineEdit
            if not folder_name:
                console_text.setText("Project name is empty. Please enter a valid name.")
                return
            
            design_files_folder = os.path.join(os.path.dirname(__file__), folder_name)
            os.makedirs(design_files_folder, exist_ok=True)
            design_file_path = os.path.join(design_files_folder, os.path.basename(input_image_path))
            if not os.path.exists(design_file_path):
                cv2.imwrite(design_file_path, image)
                console_text.setText(f"Copied image to: {design_file_path}")
            
            process_image()  # Automatically run process_image after loading the image
            process_button.setEnabled(True)  # Enable the process button
        except Exception as e:
            console_text.setText(f"Error loading image: {str(e)}")
            print(traceback.format_exc())

    def process_image():
        global image
        if image is None:
            console_text.setText("No image loaded. Please load or capture an image first.")
            return
        try:
            clear_canvas(canvas, keep_original=True)
            console_text.setText(f"Processing image.")
            folder_name = ui.lineEdit.text().strip()  # Get folder name from lineEdit
            if not folder_name:
                console_text.setText("Project name is empty. Please enter a valid name.")
                return
            diameter, threshold_input = find_diameter(image, canvas, threshold_entry, offset_entry, token_entry, resolution_entry, console_text)
            if diameter is None or threshold_input is None:
                return  # Return to main loop if the user selects "no"
            contours, offset_image = find_contours(image, diameter, threshold_input, canvas, console_text)
            dxf_path, gridx_size, gridy_size = save_contours_as_dxf(contours, file_name, float(token_entry.text()) / diameter, console_text, folder_name)
            console_text.setText(f"Processing image\nGrid X Size: {gridx_size}, Grid Y Size: {gridy_size}")
            import_button.setEnabled(True)
            import_button.dxf_path = dxf_path
            import_button.gridx_size = gridx_size
            import_button.gridy_size = gridy_size
            import_button.folder_name = folder_name  # Store folder name for import_to_openscad
        except Exception as e:
            console_text.setText(f"Error processing image: {str(e)}")
            print(traceback.format_exc())

    load_button.clicked.connect(load_image)
    process_button.clicked.connect(process_image)
    import_button.clicked.connect(lambda: import_to_openscad(import_button.dxf_path, import_button.gridx_size, import_button.gridy_size, console_text, file_name, import_button.folder_name))
    exit_button.clicked.connect(lambda: exit_application(console_text))
    
    window.showMaximized()  # Show the main window in maximized view
    app.exec_()

if __name__ == "__main__":
    main()
