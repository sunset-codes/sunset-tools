vtu_start = """
<?xml version="1.0"?>

<VTKFile type= "UnstructuredGrid"  version= "0.1"  byte_order= "BigEndian">
    <UnstructuredGrid>
"""
vtu_end = """
    </UnstructuredGrid>
</VTKFile>
"""
vtu_start_piece(n_nodes) = """
        <Piece NumberOfPoints="$n_nodes" NumberOfCells="$n_nodes">
"""
vtu_end_piece = """
        </Piece>
"""
vtu_start_points = """
            <Points>
"""
vtu_end_points = """
            </Points>
"""
vtu_start_point_data = """
            <PointData>
"""
vtu_end_point_data = """
            </PointData>
"""
vtu_start_data_array(type, name; n_components = 1) = """
                <DataArray type="$type" $(name == "" ? "" : "Name=\"$name\" ")$(n_components == 1 ? "" : string("NumberOfComponents=\"", n_components, "\" "))format="ascii">
"""

vtu_end_data_array = """
                </DataArray>
"""
vtu_start_cells = """
            <Cells>
"""
vtu_end_cells = """
            </Cells>
"""
